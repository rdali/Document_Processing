import boto3
import json
from pathlib import Path
import os
import base64


# Environment variables
OUTPUT_BUCKET = os.getenv("PROCESSED_BUCKET")
RAW_BUCKET = os.getenv("RAW_BUCKET")
REGION = os.getenv("REGION", "us-east-1")

# Initialize AWS clients
s3_client = boto3.client('s3', region_name=REGION)
bedrock_client = boto3.client('bedrock-runtime', region_name=REGION)

# Claude model ID for Anthropic Claude
MODEL_ID = "anthropic.claude-3-sonnet-20240229-v1:0"


def load_image(file_path: str) -> str:
    """loads image and base64 encodes it"""
    try:
        with open(file_path, "rb") as image:
            img = image.read()
            img_bytes = bytearray(img)
            base64_image = base64.b64encode(img_bytes).decode('utf-8')
            return base64_image
    except Exception as e:
        print(f"Error extracting text from image: {str(e)}")
        return ""

def process_document_with_claude(base64_image_data, document_type="invoice"):
    """Process document text using Claude via Bedrock"""
    
    # Define prompt for Claude based on document type
    prompt = f"""
    You are an AI assistant specialized in document information extraction.
    
    I'll provide text extracted from a {document_type}. Please extract the following information in a structured JSON format:
    
    For invoices:
    - Invoice Number
    - Invoice Date
    - Due Date
    - Vendor Name
    - Vendor Address
    - Vendor Phone Number
    - Vendor Email
    - Total Amount
    - Currency
    - Line Items (with quantities, descriptions, and prices if available)
    
    Return your response as a JSON object with the extracted fields. Precisely copy all the relevant information from the form.
    Leave the field blank if there is no information in corresponding field.
    If the image is not a {document_type}, simply return an empty JSON object. 
    If the {document_type} is not filled, leave the fees attributes blank. 
    Translate any non-English text to English. 

    """
    
    # Prepare the request payload for Claude
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4096,
        "temperature": 0.1,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt,
                    },
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/png",
                            "data": base64_image_data,
                        },
                    },
                ],
            }
        ],
    }
    
    # Call Claude via Bedrock
    try:
        response = bedrock_client.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps(request_body)
        )
        response_body = json.loads(response.get('body').read())
        
        # Extract Claude's response
        claude_response = response_body['content'][0]['text']
        return claude_response
    except Exception as e:
        print(f"Error calling Bedrock: {str(e)}")
        return {"error": str(e)}

def handler(event, context):
    """Lambda handler function"""
    
    for message in event['Records']:
        try:
            body = json.loads(message["body"])
            
            # Extract bucket_name and object key from SQS payload
            bucket_name = body["Records"][0]["s3"]["bucket"]["name"]
            object_key = body["Records"][0]["s3"]["object"]["key"]
            
            # Get file name and extension
            base_name = Path(object_key).stem
            local_file_path = f"/tmp/{object_key}"
            # Log processing start
            print(f"Processing document: {object_key} from bucket: {bucket_name}")
            
            s3_client.download_file(
                Bucket=bucket_name,
                Key=object_key,
                Filename=local_file_path
            )
            print("Downloading file Complete")

            
            # Extract text from document
            image_base64 = load_image(local_file_path)
            
            if not image_base64:
                print(f"Failed to extract text from document: {object_key}")
                return {
                    "statusCode": 500,
                    "body": json.dumps({"message": "Failed to extract text from document"})
                }
            
            # Process document with Claude
            extracted_data = process_document_with_claude(image_base64)
            
            # Save the processed results to S3
            output_key = f"{base_name}.json"
            s3_client.put_object(
                Bucket=OUTPUT_BUCKET,
                Key=output_key,
                Body=extracted_data,
                ContentType='application/json'
            )
            
            print(f"Successfully processed document. Results saved to {output_key}")
            
            return {
                "statusCode": 200,
                "body": json.dumps({"message": "Document processed successfully"})
            }
            
        except Exception as e:
            print(f"Error processing document: {str(e)}")
            return {
                "statusCode": 500,
                "body": json.dumps({"message": f"Error processing document: {str(e)}"})
            }
