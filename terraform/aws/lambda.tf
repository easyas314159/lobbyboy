module "binary" {
  source = "../modules/binary"
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*/*"
}

resource "aws_lambda_function" "this" {
  filename         = module.binary.archive_path
  function_name    = "lobbyboy"
  role             = aws_iam_role.this.arn
  runtime          = "go1.x"
  handler          = basename(module.binary.binary_path)
  source_code_hash = module.binary.archive_base64sha256
  timeout          = 10

  environment {
    variables = {
      AWS_APPCONFIG_CLIENT_ID     = "lobbyboy"
      AWS_APPCONFIG_APPLICATION   = aws_appconfig_application.this.name
      AWS_APPCONFIG_ENVIRONMENT   = aws_appconfig_environment.this.name
      AWS_APPCONFIG_CONFIGURATION = aws_appconfig_configuration_profile.this.name
    }
  }
}
