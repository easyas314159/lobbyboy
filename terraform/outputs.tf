output "twilio_voice_url" {
  value = "${aws_api_gateway_deployment.lobbyboy.invoke_url}${aws_api_gateway_resource.lobbyboy.path}"
}
