resource "aws_api_gateway_resource" "lobbyboy" {
  rest_api_id = aws_api_gateway_rest_api.lobbyboy.id
  parent_id   = aws_api_gateway_rest_api.lobbyboy.root_resource_id
  path_part   = "call"
}

resource "aws_api_gateway_method" "lobbyboy" {
  rest_api_id   = aws_api_gateway_rest_api.lobbyboy.id
  resource_id   = aws_api_gateway_resource.lobbyboy.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "lobbyboy" {
  rest_api_id = aws_api_gateway_rest_api.lobbyboy.id
  stage_name  = aws_api_gateway_deployment.lobbyboy.stage_name
  method_path = "${aws_api_gateway_resource.lobbyboy.path_part}/${aws_api_gateway_method.lobbyboy.http_method}"

  # TODO: {KL} Fix logging here
  settings {
    logging_level = "OFF"
  }
}

resource "aws_api_gateway_integration" "lobbyboy" {
  rest_api_id             = aws_api_gateway_rest_api.lobbyboy.id
  resource_id             = aws_api_gateway_resource.lobbyboy.id
  http_method             = aws_api_gateway_method.lobbyboy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lobbyboy.invoke_arn
}

resource "aws_api_gateway_method_response" "lobbyboy" {
  rest_api_id = aws_api_gateway_rest_api.lobbyboy.id
  resource_id = aws_api_gateway_resource.lobbyboy.id
  http_method = aws_api_gateway_method.lobbyboy.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "lobbyboy" {
  rest_api_id = aws_api_gateway_rest_api.lobbyboy.id
  resource_id = aws_api_gateway_resource.lobbyboy.id
  http_method = aws_api_gateway_method.lobbyboy.http_method
  status_code = aws_api_gateway_method_response.lobbyboy.status_code

  depends_on = [
    "aws_api_gateway_integration.lobbyboy",
  ]
}

resource "aws_lambda_permission" "lobbyboy" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lobbyboy.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.lobbyboy.execution_arn}/*/*/*"
}

resource "aws_cloudwatch_log_group" "lobbyboy" {
  name              = "/aws/lambda/${aws_lambda_function.lobbyboy.function_name}"
  retention_in_days = "${var.retention_in_days}"
}

resource "aws_lambda_function" "lobbyboy" {
  filename         = "../lambda/build/lobbyboy.zip"
  function_name    = "lobbyboy"
  role             = aws_iam_role.lobbyboy.arn
  handler          = "index.handle"
  runtime          = "nodejs10.x"
  source_code_hash = filebase64sha256("../lambda/build/lobbyboy.zip")
  timeout          = 120
  kms_key_arn      = aws_kms_key.lobbyboy.arn

  environment {
    variables = {
      TWILIO_SECRET = aws_kms_ciphertext.twilio_secret.ciphertext_blob

      USERS    = jsonencode(var.users)
      DELIVERY = var.delivery

      VOICE        = var.voice
      LANGUAGE     = var.language
      CALLER_ID    = var.caller_id
      ACCEPT_DIGITS = var.accept_digits
      PARTY_CODE   = var.party_code
    }
  }
}
