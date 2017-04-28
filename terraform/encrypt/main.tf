variable "profile" {}
variable "region" {}

variable "key_id" {}
variable "plain_text" {}
variable "output_file" {}

resource "null_resource" "encrypted" {
	triggers = {
		key_id = "${var.key_id}"
		plain_text = "${var.plain_text}"
	}

	provisioner "local-exec" {
		command = "aws kms encrypt --key-id ${var.key_id} --plaintext \"${var.plain_text}\" --output text --query CiphertextBlob --profile \"${var.profile}\" --region \"${var.region}\" > ${var.output_file}"
	}
}

output "encrypted" {
	value = "${file(var.output_file)}"
}
