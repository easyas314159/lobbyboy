resource "aws_api_gateway_rest_api" "lobbyboy" {
  name = "lobbyboy"
}

resource "aws_api_gateway_resource" "answer" {
  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  parent_id   = "${aws_api_gateway_rest_api.lobbyboy.root_resource_id}"
  path_part   = "answer"
}

resource "aws_api_gateway_method" "answer" {
  rest_api_id   = "${aws_api_gateway_rest_api.lobbyboy.id}"
  resource_id   = "${aws_api_gateway_resource.answer.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "answer" {
  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  stage_name  = "${aws_api_gateway_deployment.lobbyboy.stage_name}"
  method_path = "${aws_api_gateway_resource.answer.path_part}/${aws_api_gateway_method.answer.http_method}"

  settings {
    metrics_enabled = true
    logging_level = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "answer" {
  rest_api_id             = "${aws_api_gateway_rest_api.lobbyboy.id}"
  resource_id             = "${aws_api_gateway_resource.answer.id}"
  http_method             = "${aws_api_gateway_method.answer.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.answer.arn}/invocations"
}

resource "aws_api_gateway_method_response" "answer" {
  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  resource_id = "${aws_api_gateway_resource.answer.id}"
  http_method = "${aws_api_gateway_method.answer.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "answer" {
  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  resource_id = "${aws_api_gateway_resource.answer.id}"
  http_method = "${aws_api_gateway_method.answer.http_method}"
  status_code = "${aws_api_gateway_method_response.answer.status_code}"

  depends_on = [
    "aws_api_gateway_integration.answer",
  ]
}

resource "aws_api_gateway_deployment" "lobbyboy" {
  depends_on = [
    "aws_api_gateway_method.answer",
    "aws_api_gateway_integration.answer",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  stage_name  = "prod"
}

output "endpoint" {
  value = "${aws_api_gateway_deployment.lobbyboy.invoke_url}"
}
