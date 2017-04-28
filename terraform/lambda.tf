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
  source      = "encrypt"
  key_id      = "${aws_kms_key.lobbyboy.key_id}"
  plain_text  = "${var.lobbyboy_twilio_sid}"
  output_file = "twilio_sid"
  region      = "${var.aws_region}"
  profile     = "${var.aws_profile}"
}

module "twilio_secret" {
  source      = "encrypt"
  key_id      = "${aws_kms_key.lobbyboy.key_id}"
  plain_text  = "${var.lobbyboy_twilio_secret}"
  output_file = "twilio_secret"
  region      = "${var.aws_region}"
  profile     = "${var.aws_profile}"
}
