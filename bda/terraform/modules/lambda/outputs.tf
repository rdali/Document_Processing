output "lambda_trigger_bda_arn" {
  description = "ARN of the Lambda trigger BDA function"
  value       = aws_lambda_function.lambda_trigger_bda.arn
}
