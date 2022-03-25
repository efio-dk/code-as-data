data "aws_iam_policy_document" "queue" {
  for_each = local.sqs_queues

  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["sqs:*"]
    resources = ["arn:aws:sqs:${local.reg_acc}:${var.name_prefix}${each.key}"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = { for key, val in local.sqs_subscriptions : key => val if val.queue == each.key }

    content {
      sid       = "Allow ${statement.value.topic} SNS SendMessage"
      actions   = ["sqs:SendMessage"]
      resources = ["arn:aws:sqs:${local.reg_acc}:${var.name_prefix}${each.key}"]

      principals {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values = [
          "arn:aws:sns:${local.reg_acc}:${var.name_prefix}${statement.value.topic}"
        ]
      }
    }
  }
}

locals {
  # Applies default values to queue variables
  queues = defaults(var.queues, {})

  # A distinct list of sqs queues
  sqs_queues = merge(
    local.queues,
    { for entry in distinct(flatten([
      for function, config in local.functions : [
        for queue in keys(config.events.sqs) : {
          name = queue
          config = lookup(local.queues, queue, {
            visibility_timeout_seconds = null
            message_retention_seconds  = null
            delay_seconds              = null
            receive_wait_time_seconds  = null
            sns_subscriptions          = {}
          })
        }
      ] if config.events != null
    ])) : entry.name => entry.config }
  )

  # A map of sqs-queue sns subscriptions
  sqs_subscriptions = { for entry in flatten([
    for queue, config in local.sqs_queues : [
      for sns_subscription in keys(config.sns_subscriptions) :
      {
        queue = queue
        topic = sns_subscription
      }
    ]
  ]) : join("/", [entry.queue, entry.topic]) => entry }

}

resource "aws_sqs_queue" "queue" {
  for_each = local.sqs_queues

  name                       = "${var.name_prefix}${each.key}"
  visibility_timeout_seconds = each.value.visibility_timeout_seconds
  message_retention_seconds  = each.value.message_retention_seconds
  receive_wait_time_seconds  = each.value.receive_wait_time_seconds
  policy                     = data.aws_iam_policy_document.queue[each.key].json
  kms_master_key_id          = aws_kms_key.this.arn
  tags                       = var.default_tags

  depends_on = [
    aws_kms_key.this,
    aws_sns_topic.topic
  ]
}

resource "aws_sns_topic_subscription" "queue" {
  for_each = local.sqs_subscriptions

  protocol  = "sqs"
  topic_arn = aws_sns_topic.topic[each.value.topic].arn
  endpoint  = aws_sqs_queue.queue[each.value.queue].arn

  depends_on = [
    aws_sns_topic.topic,
    aws_sqs_queue.queue
  ]
}

resource "aws_lambda_event_source_mapping" "queue" {
  for_each = {
    for trigger, config in local.function_triggers : trigger => config
    if config.type == "sqs" && local.functions[config.function].image_tag != ""
  }

  event_source_arn                   = aws_sqs_queue.queue[each.value.trigger].arn
  function_name                      = aws_lambda_function.function[each.value.function].arn
  batch_size                         = local.functions[each.value.function].events.sqs[each.value.trigger].batch_size
  maximum_batching_window_in_seconds = local.functions[each.value.function].events.sqs[each.value.trigger].maximum_batching_window_in_seconds
  enabled                            = true
}
