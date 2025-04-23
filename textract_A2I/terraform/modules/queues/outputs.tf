output "textract_results_topic_arn" {
  value = aws_sns_topic.textract_results.arn
}

output "document_processing_queue_arn" {
  value = aws_sqs_queue.trigger_textract.arn
}

output "document_processing_queue_url" {
  value = aws_sqs_queue.trigger_textract.url
}

output "textract_results_queue_arn" {
  value = aws_sqs_queue.textract_results.arn
}
