resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-orders-dlq"

  tags = var.tags
}

resource "aws_sqs_queue" "orders" {
  name = "${var.project_name}-orders-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = var.tags
}