output "iam_lambda_trigger_bda_role_arn" {
  description = "ARN of the Lambda trigger BDA IAM role"
  value       = aws_iam_role.iam_lambda_trigger_bda.arn
}
