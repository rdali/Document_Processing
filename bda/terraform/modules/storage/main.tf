#----- Input Bucket:

resource "aws_s3_bucket" "input_bucket" {
  bucket = "${var.project_name}-inputs-${var.env}"
}

# Add Lambda trigger

resource "aws_s3_bucket_notification" "input_bucket_event_notification" {
  bucket = aws_s3_bucket.input_bucket.bucket
  
  dynamic "lambda_function" {
    for_each = var.extensions
    content {
      lambda_function_arn = var.lambda_trigger_bda_arn
      events              = ["s3:ObjectCreated:*"]
      #filter_prefix       = "input/"
      filter_suffix       = lambda_function.value
    }
  }
}

#----- Output Bucket:

resource "aws_s3_bucket" "output_bucket" {
  bucket = "${var.project_name}-outputs-${var.env}"
}