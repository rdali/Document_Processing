import boto3
import json
from pathlib import Path
import os
import PyPDF2


# Environment variables
OUTPUT_BUCKET = os.getenv("PROCESSED_BUCKET")
RAW_BUCKET = os.getenv("RAW_BUCKET")
REGION = os.getenv("REGION", "us-east-1")

# Initialize AWS clients
s3_client = boto3.client('s3', region_name=REGION)
bedrock_client = boto3.client('bedrock-runtime', region_name=REGION)

# Claude model ID for Anthropic Claude
MODEL_ID = "us.anthropic.claude-3-5-sonnet-20241022-v2:0"


def extract_text_from_pdf(pdf_path: str):
    """Extract text from PDF using PyPDF2 (no bounding boxes available)"""
    try:
        extracted_data = []
        
        with open(pdf_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            
            for page_num, page in enumerate(pdf_reader.pages):
                # Extract text from page
                page_text = page.extract_text()
                
                if page_text.strip():
                    # Split text into words/lines for processing
                    lines = page_text.strip().split('\n')
                    
                    for line_num, line in enumerate(lines):
                        line = line.strip()
                        if line:
                            # Split line into words
                            words = line.split()
                            for word_num, word in enumerate(words):
                                if word.strip():
                                    # Create approximate bounding box (since PyPDF2 doesn't provide positioning)
                                    # This is a rough estimate for compatibility
                                    estimated_left = (word_num * 0.1) % 1.0
                                    estimated_top = (line_num * 0.05) % 1.0
                                    estimated_width = min(0.1, len(word) * 0.01)
                                    estimated_height = 0.04
                                    
                                    bounding_box = {
                                        "left": estimated_left,
                                        "top": estimated_top,
                                        "width": estimated_width,
                                        "height": estimated_height
                                    }
                                    
                                    extracted_data.append({
                                        "text": word.strip(),
                                        "page": page_num + 1,
                                        "bounding_box": bounding_box
                                    })
        
        return extracted_data
        
    except Exception as e:
        print(f"Error extracting text from PDF: {str(e)}")
        return []


def process_document_with_claude(extracted_text_data, document_type="invoice"):
    """Process extracted text using Claude via Bedrock"""
    
    # Convert extracted data to a readable format for the LLM
    text_content = ""
    for item in extracted_text_data:
        text_content += f"Page {item['page']}: '{item['text']}' at position {item['bounding_box']}\n"
    
    # Define prompt for Claude based on document type
    prompt = f"""
    You are an AI assistant specialized in document information extraction.
    
    I'll provide text extracted from a {document_type} using PyPDF2. The text includes page numbers and estimated positioning information.
    
    Please extract the following information in a structured JSON format:
    
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
    If the document is not a {document_type}, simply return an empty JSON object. 
    If the {document_type} is not filled, leave the fees attributes blank. 
    Translate any non-English text to English.
    
    Here is the extracted text with positioning information:
    {text_content}
    """
    
    # Prepare the request payload for Claude (text-only)
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4096,
        "temperature": 0.1,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ],
    }
    
    # Save the prompt to S3
    s3_client.put_object(
        Bucket=OUTPUT_BUCKET,
        Key="prompt.txt",
        Body=prompt,
        ContentType='text/plain'
    )

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
            print(f"Processing PDF document: {object_key} from bucket: {bucket_name}")
            
            # Download PDF from S3
            s3_client.download_file(
                Bucket=bucket_name,
                Key=object_key,
                Filename=local_file_path
            )
            print("Downloading PDF file complete")
            
            # Extract text with bounding boxes from PDF
            extracted_data = extract_text_from_pdf(local_file_path)
            
            if not extracted_data:
                print(f"Failed to extract text from PDF: {object_key}")
                return {
                    "statusCode": 500,
                    "body": json.dumps({"message": "Failed to extract text from PDF"})
                }
            
            print(f"Successfully extracted {len(extracted_data)} text elements from PDF")
            
            # Process extracted text with Claude
            processed_data = process_document_with_claude(extracted_data)
            
            # Save the processed results to S3
            output_key = f"{base_name}.json"
            s3_client.put_object(
                Bucket=OUTPUT_BUCKET,
                Key=output_key,
                Body=processed_data,
                ContentType='application/json'
            )
            
            print(f"Successfully processed PDF document. Results saved to {output_key}")
            
            return {
                "statusCode": 200,
                "body": json.dumps({"message": "PDF document processed successfully"})
            }
            
        except Exception as e:
            print(f"Error processing PDF document: {str(e)}")
            return {
                "statusCode": 500,
                "body": json.dumps({"message": f"Error processing PDF document: {str(e)}"})
            }
