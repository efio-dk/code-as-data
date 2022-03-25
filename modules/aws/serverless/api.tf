locals {
  endpoints = {
    for endpoint, value in local.function_triggers :
    endpoint => value
    if value.type == "https"
  }
}

# https://learn.hashicorp.com/tutorials/terraform/lambda-api-gateway

resource "aws_apigatewayv2_api" "api" {
  count = length(local.endpoints) > 0 ? 1 : 0

  name          = "${var.name_prefix}api"
  protocol_type = "HTTP"
  tags          = local.default_tags
}

resource "aws_cloudwatch_log_group" "api" {
  count = length(local.endpoints) > 0 ? 1 : 0

  name              = "/aws/api_gw/${aws_apigatewayv2_api.api[0].name}"
  retention_in_days = var.cloudwatch_log_retention_in_days
  tags              = local.default_tags
}

resource "aws_apigatewayv2_stage" "api" {
  count = length(local.endpoints) > 0 ? 1 : 0

  api_id      = aws_apigatewayv2_api.api[0].id
  name        = "${var.name_prefix}${local.stage}"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api[0].arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_apigatewayv2_integration" "api" {
  for_each = {
    for endpoint, config in local.endpoints : endpoint => config
    if local.functions[config.function].image_tag != ""
  }

  description = "Integration for the ${var.name_prefix}${each.key} endpoint"
  api_id      = aws_apigatewayv2_api.api[0].id

  integration_uri    = aws_lambda_function.function[each.value.function].invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  # timeout_milliseconds 
}

resource "aws_apigatewayv2_route" "api" {
  for_each = {
    for endpoint, config in local.endpoints : endpoint => config
    if local.functions[config.function].image_tag != ""
  }

  api_id = aws_apigatewayv2_api.api[0].id

  route_key = join(" ", [
    upper(local.functions[each.value.function].events.https[each.value.trigger].method),
    local.functions[each.value.function].events.https[each.value.trigger].path,
  ])
  target = "integrations/${aws_apigatewayv2_integration.api[each.key].id}"
}

resource "aws_lambda_permission" "api_gw" {
  for_each = toset([
    for value in values(local.endpoints) : value.function
    if local.functions[value.function].image_tag != ""
  ])

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function[each.key].function_name

  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.api[0].execution_arn}/*/*"
}
