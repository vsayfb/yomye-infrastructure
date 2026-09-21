locals {
  name_prefix = var.name_prefix
  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "observability"
  })
}

resource "aws_ssm_parameter" "opamp_endpoint" {
  name  = "/${local.name_prefix}/observability/grafana-cloud-opamp-endpoint"
  type  = "String"
  value = var.grafana_cloud_opamp_endpoint

  tags = local.common_tags
}

data "aws_ssm_parameter" "opamp_auth_token" {
  name = var.grafana_cloud_opamp_auth_token_parameter_name
}

data "aws_ssm_parameter" "otlp_write_key" {
  name = var.grafana_cloud_otlp_write_key_parameter_name
}
