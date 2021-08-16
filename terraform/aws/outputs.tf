output "twilio_callback_url" {
  value = aws_api_gateway_deployment.this.invoke_url
}
