output "queue_url" {
  value = aws_sqs_queue.orders.url
}

output "queue_arn" {
  value = aws_sqs_queue.orders.arn
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}