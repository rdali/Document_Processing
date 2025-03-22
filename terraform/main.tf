module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  sqs_queue_arn = module.queues.document_processing_queue_arn
  sqs_queue_url = module.queues.document_processing_queue_url
  enable_cors  = true
}

module "queues" {
  source       = "./modules/queues"
  project_name = var.project_name
}

module "lambda" {
  source       = "./modules/lambda"
  project_name = var.project_name
  s3_bucket_raw_arn = module.storage.raw_bucket_arn
  s3_bucket_processed_arn = module.storage.processed_bucket_arn
  s3_bucket_raw_bucket = module.storage.raw_bucket_name
  s3_bucket_processed_bucket = module.storage.processed_bucket_name
  sns_topic_arn = module.queues.textract_results_topic_arn
  sqs_queue_arn = module.queues.document_processing_queue_arn
  textract_results_queue_arn = module.queues.textract_results_queue_arn
  a2i_private_flow_arn = module.a2i.private_flow_arn
  aws_region = var.aws_region
  
  depends_on = [
    module.storage,
    module.queues,
    module.a2i
  ]
}

module "a2i" {
  source       = "./modules/a2i"
  project_name = var.project_name
  processed_bucket = module.storage.processed_bucket_name
}

# IAM policy for Terraform state access (if needed)
resource "aws_iam_policy" "terraform_state" {
  count = var.create_state_iam_policy ? 1 : 0
  name = "terraform-state-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket_name}",
          "arn:aws:s3:::${var.state_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.state_table_name}"
      }
    ]
  })
}

# Get current AWS account ID
data "aws_caller_identity" "current" {} 