locals {
  # Applies default values to topic variables
  topics = defaults(var.topics, {})

  # A distinct list of sns topics
  sns_topics = merge(
    local.topics, // Explicit declared topics
    {             // Topics declared by function subscription
      for entry in distinct(flatten([
        for function, config in local.functions : [
          for topic in keys(config.events.sns) : {
            name = topic
            config = lookup(local.topics, topic, {
              fifo = null
            })
          }
        ] if config.events != null
      ])) : entry.name => entry.config
    },
    { // Topics declared by SQS subscriptions
      for entry in distinct(flatten([
        for queue, config in local.queues : [
          for topic in keys(config.sns_subscriptions) : {
            name = topic
            config = lookup(local.topics, topic, {
              fifo = null
            })
          }
        ] //if length(config.sns_subscriptions) > 0
      ])) : entry.name => entry.config
    },
    { // Topics decalred by function targets
      for entry in distinct(flatten([
        for function, config in local.functions : [
          for topic, value in config.targets : {
            name = topic
            config = lookup(local.topics, topic, {
              fifo = null
            })
          } if value.type == "sns"
        ] //if length(config.targets) > 0
      ])) : entry.name => entry.config
    },
  )
}

resource "aws_sns_topic" "topic" {
  for_each = local.sns_topics

  name              = "${var.name_prefix}${each.key}"
  kms_master_key_id = aws_kms_key.this.arn
  tags              = local.default_tags

  depends_on = [
    aws_kms_key.this
  ]
}
