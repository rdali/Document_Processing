#----- Lambda to Trigger BDA Processing:

resource "aws_lambda_function" "lambda_trigger_bda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-trigger-bda-lambda-${var.env}"
  role            = var.lambda_role_bda_arn
  handler         = "main.handler"
  runtime         = "python3.12"
  timeout         = 300
  memory_size     = 256
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  layers = [
    module.lambda_boto3_layer.lambda_layer_arn
  ]

  environment {
    variables = {
      REGION          = var.aws_region
      OUTPUT_BUCKET   = var.s3_bucket_outputs_name
      INPUT_BUCKET    = var.s3_bucket_inputs_name
      DATA_AUTOMATION_PROJECT_ARN = var.data_automation_project_arn
      BDA_BLUEPRINT_ARN = var.bda_blueprint_arn
    }
  }
}

# Create zip file from Lambda source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/functions/trigger_bda"
  output_path = "${path.root}/../build/trigger-bda.zip"
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_bucket_event" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_trigger_bda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.input_bucket_arn
}

# change number of retries:
resource "aws_lambda_function_event_invoke_config" "trigger_bda_config" {
  function_name = aws_lambda_function.lambda_trigger_bda.function_name
  maximum_retry_attempts = 0
}

# CloudWatch Log Group for Lambda with retention
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_trigger_bda.function_name}"
  retention_in_days = 14
}

module "lambda_boto3_layer" {
  source =  "terraform-aws-modules/lambda/aws"

  create_function = false
  create_layer = true

  layer_name               = "${var.project_name}-boto3-layer-${var.env}"
  description              = "boto3 updated lambda layer (deployed from local)"
  compatible_runtimes      = ["python3.12"]
  compatible_architectures = ["x86_64"]

  source_path = [
    {
      path = "${path.module}/../../../src/functions/"
      commands = [
        ":zip",
        "cd `mktemp -d`",
        "python3 -m pip install --no-compile --only-binary=:all: --platform=manylinux2014_x86_64 --target=./python -r ${abspath(path.module)}/../../../src/functions/trigger_bda/requirements.txt",
        ":zip .",
      ]
    }
  ]
  ignore_source_code_hash = true
}
