import boto3
import json
import time
from typing import List, Dict, Union
from pathlib import Path
import os

textract = boto3.client("textract")
s3 = boto3.client("s3")
a2i = boto3.client("sagemaker-a2i-runtime")

FLOW_PRIVATE_ARN = os.getenv("A2I_PRIVATE_FLOW_ARN")
BUCKET = os.getenv("PROCESSED_BUCKET")

# A2I decision variables:
value_detection_threshold = 90
label_detection_threshold = 90


def parse_payload(payload):
    """ method to parse SQS payload and retrieve status, bucket and object"""
    message = json.loads(payload.get("Message"))
    job_status = message["Status"]
    job_id = message["JobId"]
    bucket_name = message["DocumentLocation"]["S3Bucket"]
    raw_object_name = message["DocumentLocation"]["S3ObjectName"]
    return job_status, job_id, bucket_name, raw_object_name


def load_json_from_file(path_to_json: str):
    """Loads JSON from flat file"""
    with open(path_to_json, "r") as file:
        json_data = file.read()

    return json.loads(json_data)


def write_json(json_obj, output_name):
    """Writes json to file"""
    with open(output_name, "w") as fl:
        fl.write(json.dumps(json_obj))


def upload_to_s3(file_name, bucket_name, obj_name):
    """Uploads file to S3 bucket"""
    with open(file_name, "rb") as f:
        s3.upload_fileobj(f, bucket_name, obj_name)


def save_json_upload_s3(data, data_file_name, base_name):
    """Saves a file to Lambda /tmp then uploads it to S3"""
    data_lambda_path = "/tmp/" + data_file_name
    write_json(data, data_lambda_path)
    upload_to_s3(data_lambda_path, BUCKET, f"{base_name}/{data_file_name}")


def get_textract_output(job_id):
    """Retrieves the Textract output and re-assembles pages"""
    response = textract.get_expense_analysis(
        JobId=job_id)
    textract_job_status = response.get("JobStatus")
    textract_json = response

    while "NextToken" in response:
        response = textract.get_expense_analysis(JobId=job_id, NextToken=response["NextToken"])
        textract_json["ExpenseDocuments"].extend(response["ExpenseDocuments"])

    if "NextToken" in textract_json:
        del textract_json["NextToken"]

    return textract_job_status, textract_json


def extract_expense_header_key(record: Dict, header: bool = True):
    """Extracts invoice header key from textract payload"""
    if header:
        prefix = record.get("GroupProperties", [{}])[0].get("Types", [None])[0]
        return "%s%s" % ("%s_" % prefix if prefix is not None else "", record["Type"]["Text"])
    return record["Type"]["Text"]


def process_expense_field(expense_field: Dict, header: bool):
    """Extracts invoice header fields from textract payload"""
    key = extract_expense_header_key(expense_field, header)
    value_detection_confidence = expense_field["ValueDetection"]["Confidence"]
    value: str = expense_field["ValueDetection"]["Text"]
    value = value if len(value) != 0 else None
    label_detection_confidence = expense_field["Type"]["Confidence"]
    bounding_box = expense_field["ValueDetection"].get("Geometry", {}).get("BoundingBox", None)
    return dict(Key=key, Value=value, ValueDetectionConfidence=value_detection_confidence,
                LabelDetectionConfidence=label_detection_confidence,
                BoundingBox=bounding_box)


def create_a2i_payload_headers(header_list: List) -> List:
    """
    Creates a2i expected payload for the template used in the form of:
    a2i_payload = {"image1": "s3_file_uri",
                    pages: [ { "headers": [page_headers],
                               "lines": [page_lines_items],
                               "page": page_num
                              },
                            ]
                }

    where page_headers = [{"hdrrow": "row_num", "orighdr": "key: value", "bounding_box": {"BoundingBox"}, "validation_required"=0,1}]
    and page_lines_items = {"ITEM": {"origval": value, "bounding_box": {"BoundingBox"}, "validation_required"=0,1},
                            "PRICE": {"origval": value, "bounding_box": {"BoundingBox"}, "validation_required"=0,1},
                            "PRODUCT_CODE": {"origval": value, "bounding_box": {"BoundingBox"}, "validation_required"=0,1},
                            "QUANTITY": {"origval": value, "bounding_box": {"BoundingBox"}, "validation_required"=0,1},
                            "UNIT_PRICE": {"origval": value, "bounding_box": {"BoundingBox"}, "validation_required"=0,1},
                            "row": "row_num"}
    """
    result = []
    for index, header in enumerate(header_list):
        result.append({"hdrrow": str(index), "orighdr": "%s: %s" % (header["Key"], header["Value"]), "bounding_box": header["BoundingBox"], "validation_required": header["validation_required"]})
    return result


def create_a2i_payload_lines(lines_list: List) -> List:
    result = []
    for idx, line in enumerate(lines_list):
        d = {k: {"origval": v["Value"], "bounding_box": v["BoundingBox"], "validation_required": v["validation_required"]} if v is not None else None for k, v in line.items()}
        d["row"] = str(idx)
        result.append(d)
    return result


def generate_a2i_payload(data: List[Dict], s3_img_uri: str):
    payload = []
    for idx, record in enumerate(data):
        payload.append(
            dict(headers=create_a2i_payload_headers(record["headers"]),
                 lines=create_a2i_payload_lines(record["lines"]),
                 page=idx + 1
                 )
        )

    return dict(pages=payload, image1=s3_img_uri)


def preprocess_textract_response(textract_json: Union[List[Dict], Dict]):
    data: List[Dict] = list()
    columns = ["ITEM", "QUANTITY", "PRICE", "UNIT_PRICE", "PRODUCT_CODE"]
    for page_idx, page in enumerate(textract_json["ExpenseDocuments"]):
        summary_fields, line_items = page["SummaryFields"], page["LineItemGroups"]
        page_data = dict(headers=list(), lines=list())

        # headers
        for record in summary_fields:
            try:
                page_data["headers"].append(process_expense_field(record, header=True))
            except Exception as e:
                print(record, e)

        # lines
        lines = []
        for record in line_items:
            lines.extend(record.get("LineItems"))

        for record in lines:
            line = record["LineItemExpenseFields"]

            # flatten the columns into a dict by type
            line = {col["Type"]["Text"]: process_expense_field(col, header=False) for col in line}
            page_data["lines"].append(
                {col: line.get(col, None) for col in columns}
            )

        page_data["page"] = page_idx + 1
        data.append(page_data)

    return data


def decide_human_validation(data_dict, value_threshold, label_threshold):
    """Edits data dict to add a "validation_required" field to the dictionary
    This is a placeholder. It currently evaluates ValueDetectionConfidence & LabelDetectionConfidence > thresholds
    More complex logic can be built
    """
    requires_validation = False
    for page in data_dict:
        if page["headers"]:
            for header in page["headers"]:
                if header["ValueDetectionConfidence"] < value_threshold or header["LabelDetectionConfidence"] < label_threshold:
                    header["validation_required"] = 1
                    requires_validation = True
                else:
                    header["validation_required"] = 0
        if page["lines"]:
            for line in page["lines"]:
                for key in line:
                    if line[key]:
                        if line[key]["ValueDetectionConfidence"] < value_threshold or line[key]["LabelDetectionConfidence"] < label_threshold:
                            line[key]["validation_required"] = 1
                            requires_validation = True
                        else:
                            line[key]["validation_required"] = 0
    return requires_validation


def trigger_a2i_private(base_name, a2i_payload):
    """Triggers a human loop for the private workforce"""
    timestamp = time.strftime("%Y%m%d-%H%M%S", time.gmtime())
    loop_name = (base_name + "-" + timestamp).replace("/", "-").replace(".", "-").replace("_", "-")

    response = a2i.start_human_loop(
        HumanLoopName=loop_name,
        FlowDefinitionArn=FLOW_PRIVATE_ARN,
        HumanLoopInput={
            "InputContent": json.dumps(a2i_payload)
        },
        DataAttributes={
            "ContentClassifiers": [
                "FreeOfPersonallyIdentifiableInformation", "FreeOfAdultContent"
            ]
        }
    )
    return loop_name, response


def handler(event, context):

    for message in event["Records"]:
        # parse info from SQS payload:
        body = json.loads(message["body"])
        job_status, job_id, bucket_name, raw_object_name = parse_payload(body)

        if job_status == "SUCCEEDED":
            file_uri = bucket_name + "/" + raw_object_name
            s3_file_uri = "s3://" + file_uri
            base_name = Path(raw_object_name).stem

            # get textract response and reassemble pages. Textract paginates every 20 pages
            status, textract_json = get_textract_output(job_id)
            # upload assembled textract payload to S3:
            save_json_upload_s3(textract_json, base_name + "_textract_complete.json", base_name)

            # evaluate payload to trigger A2I if necessary
            data = preprocess_textract_response(textract_json)
            save_json_upload_s3(data, base_name + "_textract_compact.json", base_name)

            # check if validation is required:
            requires_validation = decide_human_validation(data, value_detection_threshold, label_detection_threshold)
            print(f"Requires human Validation: {requires_validation}")
            if requires_validation:

            # trigger A2I:
            # create payload:
                a2i_payload = generate_a2i_payload(data, s3_file_uri)
                save_json_upload_s3(a2i_payload, base_name + "_textract_a2i_payload.json", base_name)
                try:
                    a2i_loop_name, a2i_response = trigger_a2i_private(base_name, a2i_payload)

                    success_msg = f"A2I Job created successfully for object {raw_object_name} with Human Loop Name: {a2i_loop_name}"
                    print(success_msg)
                    return {"statusCode": 200, "body": json.dumps(success_msg)}
                except Exception as e:
                    fail_msg = "A2I Job creation failed for object " + raw_object_name
                    print(fail_msg, e)
                    return {"statusCode": 500, "body": json.dumps(fail_msg)}

        else:
            print("Textract Job failed!")
            return {"statusCode": 500, "body": "Textract Job failed!"}
