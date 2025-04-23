import boto3
import json
from pathlib import Path
import os

SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")
TEXTRACT_SNS_ROLE_ARN = os.getenv("TEXTRACT_ROLE_ARN")
OUTPUT_BUCKET = os.getenv("PROCESSED_BUCKET")

textract = boto3.client("textract")


def handler(event, context):

    for message in event['Records']:
        body = json.loads(message["body"])

        # extract bucket_name and object key from SQS payload:
        bucket_name = body["Records"][0]["s3"]["bucket"]["name"]
        object_name = body["Records"][0]["s3"]["object"]["key"]

        # get file name:
        base_name = Path(object_name).stem
  
        # start Textract
        response = textract.start_expense_analysis(
            DocumentLocation={
                "S3Object": {
                    "Bucket": bucket_name,
                    "Name": object_name
                }
            },
            JobTag=base_name,
            NotificationChannel={
                "SNSTopicArn": SNS_TOPIC_ARN,
                "RoleArn": TEXTRACT_SNS_ROLE_ARN
            },
            OutputConfig={
                "S3Bucket": OUTPUT_BUCKET,
                "S3Prefix": f"{base_name}/textract"
            }
        )
        print("...... triggered textract .......")
        job_id = response["JobId"]
        if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
            success_msg = "Job created successfully for object " + object_name + " with Job ID: " + job_id
            print(success_msg)
            return {"statusCode": 200, "body": json.dumps(success_msg)}
        else:
            fail_msg = "Job creation failed for object " + object_name + " with Job ID: " + job_id
            print(fail_msg)
            return {"statusCode": 500, "body": json.dumps(fail_msg)}
