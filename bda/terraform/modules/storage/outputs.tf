output "input_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.input_bucket.bucket
}

output "input_bucket_arn" {
  description = "ARN of the input S3 bucket"
  value       = aws_s3_bucket.input_bucket.arn
}

output "output_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.output_bucket.bucket
}

output "output_bucket_arn" {
  description = "ARN of the input S3 bucket"
  value       = aws_s3_bucket.output_bucket.arn
}
