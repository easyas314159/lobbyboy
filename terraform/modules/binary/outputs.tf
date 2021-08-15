output "binary_path" {
  value = data.archive_file.binary.source_file
}

output "archive_path" {
  value = data.archive_file.binary.output_path
}

output "archive_base64sha256" {
  value = data.archive_file.binary.output_base64sha256
}
