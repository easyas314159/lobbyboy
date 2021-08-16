locals {
  common_log_format = {
    "requestId"      = "$context.requestId"
    "ip"             = "$context.identity.sourceIp"
    "caller"         = "$context.identity.caller"
    "user"           = "$context.identity.user"
    "requestTime"    = "$context.requestTime"
    "httpMethod"     = "$context.httpMethod"
    "resourcePath"   = "$context.resourcePath"
    "status"         = "$context.status"
    "protocol"       = "$context.protocol"
    "responseLength" = "$context.responseLength"
  }
}

resource "aws_api_gateway_rest_api" "this" {
  name = var.name
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this,
  ]
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format          = jsonencode(local.common_log_format)
  }

  depends_on = [
    aws_cloudwatch_log_group.api_gateway
  ]
}

resource "aws_api_gateway_method_settings" "live" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_method" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_rest_api.this.root_resource_id
  http_method   = "POST"
  authorization = "NONE"

  request_parameters = {
    "method.request.header.X-Twilio-Signature" = true
  }
}

resource "aws_api_gateway_method_response" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_rest_api.this.root_resource_id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_rest_api.this.root_resource_id
  http_method             = aws_api_gateway_method.this.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this.invoke_arn
}
