resource "aws_iam_role" "schedule" {
  for_each = { for key, value in local.function_triggers : key => value if value.type == "schedule" }

  name = "${var.name_prefix}${each.value.function}-${each.value.trigger}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "events.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "schedule" {
  for_each = { for key, value in local.function_triggers : key => value if value.type == "schedule" }

  name                = "${var.name_prefix}${each.value.function}-${each.value.trigger}"
  description         = "Scheduled trigger to invoke lambda ${var.name_prefix}${each.value.function} function"
  role_arn            = aws_iam_role.schedule[each.key].arn
  schedule_expression = local.functions[each.value.function].events.schedules[each.value.trigger].cron
  tags                = var.default_tags
}

resource "aws_cloudwatch_event_target" "schedule" {
  for_each = {
    for trigger, config in local.function_triggers : trigger => config
    if config.type == "schedule" && local.functions[config.function].image_tag != ""
  }

  rule = aws_cloudwatch_event_rule.schedule[each.key].name
  arn  = aws_lambda_function.function[each.value.function].arn
}

resource "aws_lambda_permission" "schedule" {
  for_each = {
    for trigger, config in local.function_triggers : trigger => config
    if config.type == "schedule" && local.functions[config.function].image_tag != ""
  }

  statement_id  = "${var.name_prefix}${each.value.function}-${each.value.trigger}"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule[each.key].arn
  function_name = aws_lambda_function.function[each.value.function].function_name
}
