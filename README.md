# Document Processor

A serverless document processing pipeline using AWS Textract.

## Architecture

- S3 buckets for raw and processed documents
- SQS queues for message handling
- Lambda functions for processing
- AWS Textract for document analysis
- SNS for notifications

## Setup

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Configure AWS credentials:
   ```bash
   aws configure
   ```

3. Deploy infrastructure:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

## Project Structure 