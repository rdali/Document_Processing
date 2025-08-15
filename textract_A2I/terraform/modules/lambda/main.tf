# Create Lambda function
resource "aws_lambda_function" "trigger_textract" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-trigger-textract-lambda"
  role            = aws_iam_role.textract_trigger.arn
  handler         = "main.handler"
  runtime         = "python3.12"
  timeout         = 300
  memory_size     = 256
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN    = var.sns_topic_arn
      TEXTRACT_ROLE_ARN = aws_iam_role.textract_trigger.arn
      REGION          = var.aws_region
      PROCESSED_BUCKET = var.s3_bucket_processed_bucket
      RAW_BUCKET      = var.s3_bucket_raw_bucket
    }
  }
}

# Create zip file from Lambda source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/functions/trigger_textract"
  output_path = "${path.root}/../build/trigger_textract.zip"
}

# change number of retries:
resource "aws_lambda_function_event_invoke_config" "trigger_textract_config" {
  function_name = aws_lambda_function.trigger_textract.function_name
  maximum_retry_attempts = 0
}


# Add SQS trigger for Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.trigger_textract.arn
  batch_size       = 1
  enabled          = true
  function_response_types = ["ReportBatchItemFailures"]
}

# Create Textract Results Processor Lambda
resource "aws_lambda_function" "textract_process" {
  filename         = data.archive_file.textract_processor_zip.output_path
  function_name    = "${var.project_name}-textract-process-lambda"
  role            = aws_iam_role.textract_process.arn
  handler         = "main.handler"
  runtime         = "python3.12"
  timeout         = 300
  memory_size     = 256
  source_code_hash = data.archive_file.textract_processor_zip.output_base64sha256

  environment {
    variables = {
      PROCESSED_BUCKET = var.s3_bucket_processed_bucket
      RAW_BUCKET = var.s3_bucket_raw_bucket
      REGION          = var.aws_region
      A2I_PRIVATE_FLOW_ARN = var.a2i_private_flow_arn
    }
  }
}

# Create zip file for Textract processor Lambda
data "archive_file" "textract_processor_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/functions/textract_process"
  output_path = "${path.root}/../build/textract_process.zip"
}

# change number of retries:
resource "aws_lambda_function_event_invoke_config" "textract_processor_config" {
  function_name = aws_lambda_function.textract_process.function_name
  maximum_retry_attempts = 0
}

# Add SQS trigger for Textract processor Lambda
resource "aws_lambda_event_source_mapping" "textract_sqs_trigger" {
  event_source_arn = var.textract_results_queue_arn
  function_name    = aws_lambda_function.textract_process.arn
  batch_size       = 1
  enabled          = true
  function_response_types = ["ReportBatchItemFailures"]
} 