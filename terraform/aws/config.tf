resource "aws_appconfig_application" "this" {
  name        = var.name
  description = "Lobby Boy"
}

resource "aws_appconfig_environment" "this" {
  name           = "live"
  application_id = aws_appconfig_application.this.id

}

resource "aws_appconfig_configuration_profile" "this" {
  name           = "current"
  application_id = aws_appconfig_application.this.id
  location_uri   = "hosted"

  validator {
    type    = "JSON_SCHEMA"
    content = file(var.config_schema)
  }
}

resource "aws_appconfig_hosted_configuration_version" "current" {
  application_id           = aws_appconfig_application.this.id
  configuration_profile_id = aws_appconfig_configuration_profile.this.configuration_profile_id
  content_type             = "application/json"

  content = file(var.config_file)
}

resource "aws_appconfig_deployment" "this" {
  application_id           = aws_appconfig_application.this.id
  environment_id           = aws_appconfig_environment.this.environment_id
  configuration_profile_id = aws_appconfig_configuration_profile.this.configuration_profile_id
  configuration_version    = aws_appconfig_hosted_configuration_version.current.version_number
  deployment_strategy_id   = aws_appconfig_deployment_strategy.this.id
}

resource "aws_appconfig_deployment_strategy" "this" {
  name                           = "immediate"
  deployment_duration_in_minutes = 0
  growth_factor                  = 100
  growth_type                    = "LINEAR"
  replicate_to                   = "NONE"
}
