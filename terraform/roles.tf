data "aws_iam_policy_document" "assume_lambda" {
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
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.lobbyboy.arn,
    ]
  }
}

data "aws_iam_policy_document" "decrypt" {
  statement {
    actions = [
      "kms:Decrypt",
    ]

    resources = [
      aws_kms_key.lobbyboy.arn,
    ]
  }
}

resource "aws_iam_role" "lobbyboy" {
  name               = "lobbyboy"
  assume_role_policy = "${data.aws_iam_policy_document.assume_lambda.json}"
}

resource "aws_iam_role_policy" "lobbyboy_logging" {
  name = "logging"
  role = aws_iam_role.lobbyboy.id

  policy = data.aws_iam_policy_document.logging.json
}

resource "aws_iam_role_policy" "lobbyboy_decrypt" {
  name = "decrypt"
  role = aws_iam_role.lobbyboy.id

  policy = data.aws_iam_policy_document.decrypt.json
}
