output "document_processing_queue_arn" {
  value = aws_sqs_queue.trigger_textract.arn
}

output "document_processing_queue_url" {
  value = aws_sqs_queue.trigger_textract.url
}
