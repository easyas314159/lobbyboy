resource "aws_api_gateway_resource" "dial" {
  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  parent_id   = "${aws_api_gateway_rest_api.lobbyboy.root_resource_id}"
  path_part   = "dial"
}

resource "aws_api_gateway_method" "dial" {
  rest_api_id   = "${aws_api_gateway_rest_api.lobbyboy.id}"
  resource_id   = "${aws_api_gateway_resource.dial.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "dial" {
  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  stage_name  = "${aws_api_gateway_deployment.lobbyboy.stage_name}"
  method_path = "${aws_api_gateway_resource.dial.path_part}/${aws_api_gateway_method.dial.http_method}"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "dial" {
  rest_api_id             = "${aws_api_gateway_rest_api.lobbyboy.id}"
  resource_id             = "${aws_api_gateway_resource.dial.id}"
  http_method             = "${aws_api_gateway_method.dial.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.dial.arn}/invocations"
}

resource "aws_api_gateway_method_response" "dial" {
  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  resource_id = "${aws_api_gateway_resource.dial.id}"
  http_method = "${aws_api_gateway_method.dial.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "dial" {
  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  resource_id = "${aws_api_gateway_resource.dial.id}"
  http_method = "${aws_api_gateway_method.dial.http_method}"
  status_code = "${aws_api_gateway_method_response.dial.status_code}"

  depends_on = [
    "aws_api_gateway_integration.dial",
  ]
}

resource "aws_lambda_permission" "dial" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.dial.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.account.account_id}:${aws_api_gateway_rest_api.lobbyboy.id}/*/${aws_api_gateway_method.dial.http_method}/dial"
}

resource "aws_lambda_function" "dial" {
  filename         = "${path.module}/../lambda.zip"
  function_name    = "lobbyboy-dial"
  role             = "${aws_iam_role.lobbyboy.arn}"
  handler          = "dial.lambda_handler"
  runtime          = "python3.6"
  source_code_hash = "${base64sha256(file("${path.module}/../lambda.zip"))}"
  timeout          = 120
  kms_key_arn      = "${aws_kms_key.lobbyboy.arn}"

  environment {
    variables = {
      kmsEncryptedTwilioSid    = "${module.twilio_sid.encrypted}"
      kmsEncryptedTwilioSecret = "${module.twilio_secret.encrypted}"
      whitelist                = "${var.lobbyboy_whitelist}"
      users                    = "${var.lobbyboy_users}"
      secrets                  = "${var.lobbyboy_secrets}"
      acceptDigit              = "${var.lobbyboy_accept_digit}"
    }
  }

  depends_on = [
    "module.twilio_sid",
    "module.twilio_secret",
  ]
}
