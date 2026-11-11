locals {
  saga_queues = {
    "oficina-billing-comandos"  = "billing"
    "oficina-execucao-comandos" = "execution"
    "oficina-os-saga-respostas" = "saga"
  }
}

resource "aws_sqs_queue" "saga_dlq" {
  for_each = local.saga_queues

  name                        = "${each.key}-dlq.fifo"
  fifo_queue                  = true
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  content_based_deduplication = false

  tags = {
    Name      = "${each.key}-dlq.fifo"
    Component = each.value
    Purpose   = "saga-dead-letter"
  }
}

resource "aws_sqs_queue" "saga" {
  for_each = local.saga_queues

  name                        = "${each.key}.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
  message_retention_seconds   = 345600
  visibility_timeout_seconds  = 30
  sqs_managed_sse_enabled     = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.saga_dlq[each.key].arn
    maxReceiveCount     = 5
  })

  tags = {
    Name      = "${each.key}.fifo"
    Component = each.value
    Purpose   = "saga"
  }
}
