resource "aws_kms_key" "lobbyboy" {
  description             = "lobbyboy"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "lobbyboy" {
  name          = "alias/lobbyboy"
  target_key_id = "${aws_kms_key.lobbyboy.key_id}"
}

resource "aws_kms_ciphertext" "twilio_secret" {
  key_id    = aws_kms_key.lobbyboy.key_id
  plaintext = var.twilio_secret
}
