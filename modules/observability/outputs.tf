output "opamp_endpoint_parameter_name" {
  value = aws_ssm_parameter.opamp_endpoint.name
}

output "opamp_auth_token_parameter_name" {
  value = data.aws_ssm_parameter.opamp_auth_token.name
}

output "observability_read_policy_arn" {
  value = aws_iam_policy.observability_read.arn
}
