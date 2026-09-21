output "app_deployments_bucket_name" {
  value = aws_s3_bucket.app_deployments.id
}

output "github_actions_deploy_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}

output "app_deployments_read_policy_arn" {
  value = aws_iam_policy.app_deployments_read.arn
}
