import boto3
import os
import json
from pathlib import Path
from datetime import datetime

REGION = os.getenv("REGION")
INPUT_BUCKET = os.getenv("INPUT_BUCKET")
OUTPUT_BUCKET = os.getenv("OUTPUT_BUCKET")
DATA_AUTOMATION_PROJECT_ARN = os.getenv("DATA_AUTOMATION_PROJECT_ARN")
BDA_BLUEPRINT_ARN = os.getenv("BDA_BLUEPRINT_ARN")

bedrock_runtime_client = boto3.client('bedrock-data-automation-runtime')


def handler(event, context):

    account_id = context.invoked_function_arn.split(":")[4]
    DATA_AUTOMATION_PROFILE_ARN = f"arn:aws:bedrock:{REGION}:{account_id}:data-automation-profile/us.data-automation-v1"

    for message in event['Records']:

        bucket_name = message["s3"]["bucket"]["name"]
        object_name = message["s3"]["object"]["key"]
        base_name = Path(object_name).stem

        input_s3_uri = f"s3://{bucket_name}/{object_name}"
        output_s3_uri = f"s3://{OUTPUT_BUCKET}/{base_name}"

        # trigger BDA
        print("Invoking Bedrock Data Automation async API with specific blueprint...")
        response = bedrock_runtime_client.invoke_data_automation_async(
            inputConfiguration={
                's3Uri': input_s3_uri
            },
            outputConfiguration={
                's3Uri': output_s3_uri
            },
            dataAutomationConfiguration={
                'dataAutomationProjectArn': DATA_AUTOMATION_PROJECT_ARN,
                'stage': 'LIVE'
            },
            dataAutomationProfileArn= DATA_AUTOMATION_PROFILE_ARN
        )

        # Log invocation info
        invocation_info = {
            'request_id': response['ResponseMetadata']['RequestId'],
            'date': datetime.now().strftime("%Y-%m-%d"),
            'invocation_arn': response['invocationArn'],
            'input_document': input_s3_uri,
            'output_location': output_s3_uri,
            'status': 'INITIATED'
        }

        print(f"...... triggered BDA with {invocation_info}.......")
  
        if response["invocationArn"]:
            success_msg = "Job created successfully for object " + object_name
            print(success_msg)
            return {"statusCode": 200, "body": json.dumps(success_msg)}
        else:
            fail_msg = "Job creation failed for object " + object_name
            print(fail_msg)
            return {"statusCode": 500, "body": json.dumps(fail_msg)}
