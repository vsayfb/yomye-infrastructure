output "function_name" {
  value = aws_lambda_function.notification.function_name
}

output "function_arn" {
  value = aws_lambda_function.notification.arn
}

output "role_arn" {
  value = aws_iam_role.lambda.arn
}

output "deployments_bucket_name" {
  value = aws_s3_bucket.deployments.id
}

output "deployments_bucket_arn" {
  value = aws_s3_bucket.deployments.arn
}
