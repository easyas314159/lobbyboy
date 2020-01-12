resource "aws_api_gateway_rest_api" "lobbyboy" {
  name = "lobbyboy"
}

resource "aws_api_gateway_deployment" "lobbyboy" {
  depends_on = [
    "aws_api_gateway_method.lobbyboy",
    "aws_api_gateway_integration.lobbyboy",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.lobbyboy.id}"
  stage_name  = "prod"
}
