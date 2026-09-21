resource "aws_sqs_queue" "category_events" {
  name                       = var.category_events_queue_name
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds

  tags = merge(local.common_tags, {
    Name = var.category_events_queue_name
  })
}

resource "aws_sqs_queue" "chat_events" {
  name                       = var.chat_events_queue_name
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds

  tags = merge(local.common_tags, {
    Name = var.chat_events_queue_name
  })
}

resource "aws_sqs_queue" "notification_events" {
  name                       = var.notification_events_queue_name
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds
  message_retention_seconds  = var.sqs_message_retention_seconds

  tags = merge(local.common_tags, {
    Name = var.notification_events_queue_name
  })
}
