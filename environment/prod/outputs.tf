output "vpc_id" {
  value = module.network.vpc_id
}

output "nat_instance_public_ip" {
  description = "NAT Instance Public IP."
  value       = module.network.nat_instance_public_ip
}

output "compute_az" {
  description = "The availability zone where everything actually runs."
  value       = module.data.compute_az
}

# RDS

output "rds_db_name" {
  description = "RDS DB Name."
  value       = module.data.rds_db_name
}

output "rds_endpoint" {
  description = "RDS DB Endpoint."
  value       = module.data.rds_endpoint
}

output "rds_address" {
  description = "RDS Address."
  value       = module.data.rds_address
}

output "rds_port" {
  description = "RDS Host."
  value       = module.data.rds_port
}

output "rds_master_username" {
  description = "Auto-generated master username."
  value       = module.data.rds_master_username
}

output "rds_master_user_secret_arn" {
  description = "Auto-generated master password."
  value       = module.data.rds_master_user_secret_arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.compute.alb_dns_name
}

output "core_chat_instance_ip" {
  value = module.compute.core_chat_instance_ip
}

output "worker_instance_ip" {
  value = module.compute.worker_instance_ip
}

output "app_deployments_bucket_name" {
  value = module.deploy.app_deployments_bucket_name
}

output "lambda_deployments_bucket_name" {
  value = module.lambda.deployments_bucket_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "github_actions_deploy_role_arn" {
  value = module.deploy.github_actions_deploy_role_arn
}
