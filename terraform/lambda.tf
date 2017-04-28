data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/"
  output_path = "${path.module}/../lambda.zip"
}

resource "aws_kms_key" "lobbyboy" {
  description             = "lobbyboy"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "lobbyboy" {
  name          = "alias/lobbyboy"
  target_key_id = "${aws_kms_key.lobbyboy.key_id}"
}

module "twilio_sid" {
  source = "encrypt"
  key_id = "${aws_kms_key.lobbyboy.key_id}"
  plain_text = "${var.lobbyboy_twilio_sid}"
  output_file = "twilio_sid"
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

module "twilio_secret" {
  source = "encrypt"
  key_id = "${aws_kms_key.lobbyboy.key_id}"
  plain_text = "${var.lobbyboy_twilio_secret}"
  output_file = "twilio_secret"
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

data "aws_iam_policy_document" "logging" {
  statement {
    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.account.account_id}:*",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.account.account_id}:log-group:/aws/lambda/lobbyboy:*",
    ]
  }
}

data "aws_iam_policy_document" "decrypt" {
  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "lobbyboy_logging" {
  name = "lobbyboy_logging"
  role = "${aws_iam_role.role.id}"

  policy = "${data.aws_iam_policy_document.logging.json}"
}

resource "aws_iam_role_policy" "lobbyboy_decrypt" {
  name = "lobbyboy_decrypt"
  role = "${aws_iam_role.role.id}"

  policy = "${data.aws_iam_policy_document.decrypt.json}"
}

resource "aws_iam_role" "role" {
  name = "lobbyboy"

  assume_role_policy = "${data.aws_iam_policy_document.role.json}"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.answer.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.account.account_id}:${aws_api_gateway_rest_api.lobbyboy.id}/*/${aws_api_gateway_method.answer.http_method}/answer"
}

resource "aws_lambda_function" "answer" {
  filename         = "${path.module}/../lambda.zip"
  function_name    = "lobbyboy"
  role             = "${aws_iam_role.role.arn}"
  handler          = "answer.lambda_handler"
  runtime          = "python3.6"
  source_code_hash = "${base64sha256(file("${path.module}/../lambda.zip"))}"
  timeout          = 120
  kms_key_arn = "${aws_kms_key.lobbyboy.arn}"

  environment {
    variables = {
      kmsEncryptedTwilioSid = "${module.twilio_sid.encrypted}"
      kmsEncryptedTwilioSecret = "${module.twilio_secret.encrypted}"
      whitelist   = "${var.lobbyboy_whitelist}"
      users       = "${var.lobbyboy_users}"
      secrets     = "${var.lobbyboy_secrets}"
      default     = "${var.lobbyboy_default}"
      acceptDigit = "${var.lobbyboy_accept_digit}"
    }
  }

  depends_on = [
    "module.twilio_sid",
    "module.twilio_secret"
  ]
}
