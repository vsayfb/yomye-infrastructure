variable "name_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "grafana_cloud_opamp_endpoint" {
  description = "Grafana Cloud Fleet Management OpAMP endpoint."
  type        = string
}

variable "grafana_cloud_opamp_auth_token_parameter_name" {
  description = "Name of the SSM SecureString parameter holding the OpAMP Authorization header value."
  type        = string
}

variable "grafana_cloud_otlp_write_key_parameter_name" {
  description = "Name of the SSM SecureString parameter holding the value of write key."
  type        = string
}


