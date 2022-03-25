data "aws_ssm_parameter" "secret" {
  for_each = {
    for key, value in local.function_env_vars :
    key => value if value.type == "ssm_secure_string"
  }

  name            = each.value.value
  with_decryption = true
}

locals {
  # Applies default values to function variables
  functions = { for function, config in
    defaults(var.functions, {
      timeout               = 5
      memory_size           = 128
      image_tag             = ""
      environment_variables = {}
      targets               = {}
      permissions           = {}

      events = {
        sns       = {}
        sqs       = {}
        schedules = {}
        https     = {}
      }
    }) :
    function => merge(config, {
      image_tag = var.functions[function].image_tag != null ? var.functions[function].image_tag : lookup(var.image_tags, function, var.default_image_tag != null ? var.default_image_tag : "")
    })
  }
  function_triggers = merge(
    { for entry in flatten([ // SNS events
      for function, config in local.functions : [
        for topic in keys(config.events.sns) : [{
          function = function
          trigger  = topic
          type     = "sns"
        }]
      ] if config.events != null
    ]) : join("/", [entry.function, entry.type, entry.trigger]) => entry },

    { for entry in flatten([ // SQS events
      for function, config in local.functions : [
        for queue in keys(config.events.sqs) : [{
          function = function
          trigger  = queue
          type     = "sqs"
        }]
      ] if config.events != null
    ]) : join("/", [entry.function, entry.type, entry.trigger]) => entry },

    { for entry in flatten([ // CloudWatch events (Schedules)
      for function, config in local.functions : [
        for schedule in keys(config.events.schedules) : [{
          function = function
          trigger  = schedule
          type     = "schedule"
        }]
      ] if config.events != null
    ]) : join("/", [entry.function, entry.type, entry.trigger]) => entry },

    { for entry in flatten([ // API GW Endpoints
      for function, config in local.functions : [
        for endpoint in keys(config.events.https) : [{
          function = function
          trigger  = endpoint
          type     = "https"
        }]
      ] if config.events != null
    ]) : join("/", [entry.function, entry.type, entry.trigger]) => entry },

  )

  function_env_vars = { for entry in flatten([
    for function, config in local.functions : [
      for key, variable in config.environment_variables : [{
        function = function
        variable = key
        type     = variable.type
        value    = variable.value
      }]
    ]
  ]) : join("/", [entry.function, entry.variable]) => entry }

  env_vars = { for function, config in local.functions :
    function => merge(
      {
        for k, v in local.function_env_vars :
        v.variable => v.value
        if v.function == function && v.type == "string"
      },
      {
        for k, v in local.function_env_vars :
        v.variable => data.aws_ssm_parameter.secret[k].value
        if v.function == function && v.type == "ssm_secure_string"
      },
      {
        for k, v in local.functions[function].targets :
        v.env_var_key => aws_sns_topic.topic[k].arn
        if v.type == "sns"
      },
      {
        for k, v in local.functions[function].targets :
        v.env_var_key => aws_sqs_queue.queue[k].arn
        if v.type == "sqs"
      }
    ) if length(config.environment_variables) + length(config.targets) > 0
  }
}

resource "aws_cloudwatch_log_group" "function" {
  for_each = local.functions

  name              = "/aws/lambda/${var.name_prefix}${each.key}"
  retention_in_days = var.cloudwatch_log_retention_in_days
  kms_key_id        = aws_kms_key.this.arn
  tags              = local.default_tags
}

resource "aws_iam_role" "function" {
  for_each = local.functions

  name = "${var.name_prefix}${each.key}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "LambdaAssumeRole",
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
      }
    ]
  })

  inline_policy {
    name = "logs"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "${aws_cloudwatch_log_group.function[each.key].arn}:*"
          "Effect" : "Allow"
        }
      ]
    })
  }

  inline_policy {
    name = "kms"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow"
          "Action" : [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource" : aws_kms_key.this.arn
        }
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = {
      for trigger, config in local.function_triggers :
      trigger => config if config.function == each.key && config.type == "sqs"
    }

    content {
      name = "sqs-trigger-${inline_policy.value.trigger}"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : [
              "sqs:ReceiveMessage",
              "sqs:DeleteMessage",
              "sqs:GetQueueAttributes",
            ],
            "Resource" : aws_sqs_queue.queue[inline_policy.value.trigger].arn
            "Effect" : "Allow"
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = {
      for target, info in each.value.targets :
      target => info if info.type == "sns"
    }

    content {
      name = "sns-trigger-${inline_policy.key}-target"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : [
              "sns:Publish",
              "sns:GetTopicAttributes"
            ],
            "Resource" : aws_sns_topic.topic[inline_policy.key].arn
            "Effect" : "Allow"
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = each.value.permissions

    content {
      name = inline_policy.key
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : inline_policy.value.actions,
            "Resource" : inline_policy.value.resource
            "Effect" : "Allow"
          }
        ]
      })
    }
  }
}

resource "aws_lambda_function" "function" {
  for_each = { for key, value in local.functions : key => value if value.image_tag != "" }

  package_type  = "Image"
  function_name = "${var.name_prefix}${each.key}"
  role          = aws_iam_role.function[each.key].arn
  description   = each.value.description
  image_uri     = "${aws_ecr_repository.registry[each.key].repository_url}:${each.value.image_tag}"
  kms_key_arn   = aws_kms_key.this.arn
  memory_size   = each.value.memory_size
  timeout       = each.value.timeout
  publish       = false
  tags          = var.default_tags

  dynamic "environment" {
    for_each = { for k, v in local.env_vars : k => v if k == each.key }

    content {
      variables = environment.value
    }
  }
}
