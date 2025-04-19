# S3 Bucket outputs
output "s3_bucket_raw_arn" {
  description = "ARN of the S3 bucket for raw documents"
  value       = module.storage.raw_bucket_arn
}

output "s3_bucket_processed_arn" {
  description = "ARN of the S3 bucket for processed documents"
  value       = module.storage.processed_bucket_arn
}

# SNS Topic output
output "sns_topic_arn" {
  description = "ARN of the SNS topic for Textract results"
  value       = module.queues.textract_results_topic_arn
}

# SQS Queue outputs
output "sqs_queue_arn" {
  description = "ARN of the SQS queue for document processing"
  value       = module.queues.document_processing_queue_arn
}

output "textract_results_queue_arn" {
  description = "ARN of the SQS queue for Textract results"
  value       = module.queues.textract_results_queue_arn
} 