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
      "kms:Decrypt",
    ]

    resources = [
      "*",
    ]
  }
}

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

resource "aws_iam_role_policy" "lobbyboy_logging" {
  name = "lobbyboy_logging"
  role = "${aws_iam_role.lobbyboy.id}"

  policy = "${data.aws_iam_policy_document.logging.json}"
}

resource "aws_iam_role_policy" "lobbyboy_decrypt" {
  name = "lobbyboy_decrypt"
  role = "${aws_iam_role.lobbyboy.id}"

  policy = "${data.aws_iam_policy_document.decrypt.json}"
}
