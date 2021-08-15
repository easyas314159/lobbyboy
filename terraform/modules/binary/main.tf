data "archive_file" "sources" {
  type        = "zip"
  source_dir  = "${path.module}/../../../go"
  output_path = "${path.module}/../../../lobbyboy-sources.zip"
}

resource "null_resource" "build" {
  triggers = {
    sources_path = data.archive_file.sources.output_path
    sources_hash = data.archive_file.sources.output_sha
  }

  provisioner "local-exec" {
    working_dir = data.archive_file.sources.source_dir
    environment = {
      GOOS = "linux"
    }
    command = "go build -o ../lobbyboy-serverless -tags serverless ./cmd/lobbyboy"
  }
}

data "archive_file" "binary" {
  type = "zip"

  source_file = "${path.module}/../../../lobbyboy-serverless"
  output_path = "${path.module}/../../../lobbyboy-serverless.zip"

  depends_on = [
    null_resource.build,
  ]
}
