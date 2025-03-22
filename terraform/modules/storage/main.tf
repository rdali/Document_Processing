resource "aws_s3_bucket" "raw" {
  bucket = "${var.project_name}-raw-documents"
}

# Add bucket policy to allow A2I to read documents
resource "aws_s3_bucket_policy" "raw" {
  bucket = aws_s3_bucket.raw.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowA2IAccess"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.raw.arn,
          "${aws_s3_bucket.raw.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_cors_configuration" "this" {
  count         = var.enable_cors ? 1 : 0
  bucket        = aws_s3_bucket.raw.id

  cors_rule {
    allowed_methods = ["GET","PUT"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    expose_headers = []
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "processed" {
  bucket = "${var.project_name}-processed-documents"
}


# Add S3 bucket notification to SQS
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.raw.id

  queue {
    queue_arn     = var.sqs_queue_arn
    events        = ["s3:ObjectCreated:Put"]
    filter_suffix = ".pdf"
  }
}

# Add SQS queue policy to allow S3 notifications
resource "aws_sqs_queue_policy" "s3_to_sqs" {
  queue_url = var.sqs_queue_url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = var.sqs_queue_arn
        Condition = {
          ArnLike = {
            "aws:SourceArn": aws_s3_bucket.raw.arn
          }
        }
      }
    ]
  })
} 