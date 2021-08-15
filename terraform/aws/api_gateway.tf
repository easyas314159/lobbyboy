locals {
  enpoints = [
    "menu",
    "gather",
    "open",
  ]
}

resource "aws_api_gateway_rest_api" "this" {
  name = "lobbyboy"
}

resource "aws_api_gateway_deployment" "live" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_appconfig_environment.this.name

  depends_on = [
    aws_api_gateway_resource.this,
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this,
  ]
}

resource "aws_api_gateway_method_settings" "live" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_deployment.live.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_resource" "this" {
  for_each    = toset(local.enpoints)
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "this" {
  for_each      = toset(local.enpoints)
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this[each.key].id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "this" {
  for_each    = toset(local.enpoints)
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this[each.key].id
  http_method = aws_api_gateway_method.this[each.key].http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "this" {
  for_each                = toset(local.enpoints)
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this[each.key].id
  http_method             = aws_api_gateway_method.this[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this.invoke_arn
}
