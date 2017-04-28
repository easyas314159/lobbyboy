resource "aws_api_gateway_rest_api" "lobbyboy" {
  name = "lobbyboy"
}

resource "aws_api_gateway_deployment" "lobbyboy" {
  depends_on = [
    "aws_api_gateway_method.answer",
    "aws_api_gateway_integration.answer",
    "aws_api_gateway_method.dial",
    "aws_api_gateway_integration.dial",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  stage_name  = "prod"
}
