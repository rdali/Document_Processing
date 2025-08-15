# Create Lambda layer for PyMuPDF and dependencies
module "lambda_dependencies_layer" {
  source = "terraform-aws-modules/lambda/aws"

  create_function = false
  create_layer = true

  layer_name               = "${var.project_name}-pypdf2-layer"
  description              = "PyPDF2 and dependencies lambda layer (deployed from local)"
  compatible_runtimes      = ["python3.12"]
  compatible_architectures = ["x86_64"]

  source_path = [
    {
      path = "${path.module}/../../../src/functions/"
      commands = [
        ":zip",
        "cd `mktemp -d`",
        "python3 -m pip install --no-compile --only-binary=:all: --platform=manylinux2014_x86_64 --target=./python -r ${abspath(path.module)}/../../../src/functions/trigger_bedrock/requirements.txt",
        ":zip .",
      ]
    }
  ]
  ignore_source_code_hash = true
}

# Create zip file from Lambda source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/functions/trigger_bedrock"
  output_path = "${path.root}/../build/trigger_bedrock.zip"
}

# Create Lambda function
resource "aws_lambda_function" "bedrock_trigger" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-trigger-bedrock-lambda"
  role            = aws_iam_role.bedrock_trigger.arn
  handler         = "main.handler"
  runtime         = "python3.12"
  timeout         = 300
  memory_size     = 256
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  layers          = [module.lambda_dependencies_layer.lambda_layer_arn]

  environment {
    variables = {
      REGION          = var.aws_region
      PROCESSED_BUCKET = var.s3_bucket_processed_bucket
      RAW_BUCKET      = var.s3_bucket_raw_bucket
    }
  }
}

# change number of retries:
resource "aws_lambda_function_event_invoke_config" "trigger_bedrock_config" {
  function_name = aws_lambda_function.bedrock_trigger.function_name
  maximum_retry_attempts = 0
}

# Add SQS trigger for Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.bedrock_trigger.arn
  batch_size       = 1
  enabled          = true
  function_response_types = ["ReportBatchItemFailures"]
}