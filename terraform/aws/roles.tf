data "aws_iam_policy_document" "assume_role" {
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

data "aws_iam_policy_document" "logging" {
  statement {
    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.this.account_id}:*",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.this.account_id}:log-group:/aws/lambda/lobbyboy:*",
    ]
  }
}

data "aws_iam_policy_document" "appconfig" {
  statement {
    actions = [
      "appconfig:GetConfiguration",
    ]

    resources = [
      aws_appconfig_application.this.arn,
      aws_appconfig_environment.this.arn,
      aws_appconfig_configuration_profile.this.arn,
    ]
  }
}

resource "aws_iam_role" "this" {
  name               = "lobbyboy"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "logging" {
  name = "logging"
  role = aws_iam_role.this.id

  policy = data.aws_iam_policy_document.logging.json
}

resource "aws_iam_role_policy" "appconfig" {
  name = "appconfig"
  role = aws_iam_role.this.id

  policy = data.aws_iam_policy_document.appconfig.json
}
