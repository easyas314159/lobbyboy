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
    metrics_enabled    = true
    logging_level      = "INFO"
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

resource "aws_lambda_permission" "answer" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.answer.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.account.account_id}:${aws_api_gateway_rest_api.lobbyboy.id}/*/${aws_api_gateway_method.answer.http_method}/answer"
}

resource "aws_lambda_function" "answer" {
  filename         = "${path.module}/../lambda.zip"
  function_name    = "lobbyboy-answer"
  role             = "${aws_iam_role.lobbyboy.arn}"
  handler          = "answer.lambda_handler"
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
      default                  = "${var.lobbyboy_default}"
      acceptDigit              = "${var.lobbyboy_accept_digit}"
    }
  }

  depends_on = [
    "module.twilio_sid",
    "module.twilio_secret",
  ]
}
