variable "name_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "core_chat_instance_name_tag" {
  type    = string
  default = null
}

variable "worker_instance_name_tag" {
  type    = string
  default = null
}

# GitHub Actions OIDC

variable "github_org" {
  description = "GitHub org/user that owns the app repos allowed to assume the deploy role."
  type        = string
}

variable "github_repo_env_name" {
  type = string
}


variable "github_repos" {
  description = "Repo names (without org prefix) whose workflows can assume the deploy role."
  type        = list(string)
}

# Lambda deploy

variable "lambda_function_arn" {
  description = "From lambda/ - lets the GitHub Actions role call UpdateFunctionCode on this specific function only."
  type        = string
}

variable "lambda_deployments_bucket_arn" {
  description = "From lambda/ - its OWN dedicated bucket, separate from this module's app_deployments bucket."
  type        = string
}
