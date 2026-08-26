module "network" {
  source = "../../modules/network"

  name_prefix    = var.name_prefix
  azs            = var.azs
  app_port_range = var.app_port_range
}

module "data" {
  source = "../../modules/data"

  name_prefix             = var.name_prefix
  environment             = var.environment
  private_subnet_ids      = module.network.private_subnet_ids
  rds_sg_id               = module.network.rds_sg_id
  compute_az              = var.azs[0]
  db_name                 = var.db_name
  mongo_db_name           = var.mongo_db_name
  groq_ai_endpoint        = var.groq_ai_endpoint
  groq_ai_model           = var.groq_ai_model
  open_router_ai_endpoint = var.open_router_base_url
  open_router_ai_model    = var.open_router_model
  gemini_ai_model         = var.gemini_model
  nvidia_ai_endpoint      = var.nvidia_base_url
  nvidia_ai_model         = var.nvidia_model
  mistral_ai_model        = var.mistral_ai_model
  mistral_ai_endpoint     = var.mistral_ai_endpoint

  db_allocated_storage       = var.db_allocated_storage
  db_backup_retention_days   = var.db_backup_retention_days
  google_client_id           = var.google_client_id
  jwt_secret_name            = var.jwt_secret_name
  mongo_db_uri_secret_name   = var.mongo_db_uri_secret_name
  groq_ai_secret_name        = var.groq_ai_secret_name
  open_router_ai_secret_name = var.open_router_ai_secret_name
  nvidia_ai_secret_name      = var.nvidia_ai_secret_name
  gemini_ai_secret_name      = var.gemini_ai_secret_name
  mistral_ai_secret_name     = var.mistral_ai_secret_name

  cloudinary_api_key         = var.cloudinary_api_key
  cloudinary_cloud_name      = var.cloudinary_cloud_name
  cloudinary_api_secret_name = var.cloudinary_api_secret_name

  r2_access_key_id     = var.r2_access_key_id
  r2_bucket            = var.r2_bucket
  r2_secret_access_key = var.r2_secret_access_key
  r2_account_id        = var.r2_account_id
  ws_allowed_origins   = var.ws_allowed_origins
}

module "compute" {
  source = "../../modules/compute"

  aws_region  = var.aws_region
  name_prefix = var.name_prefix

  vpc_id                 = module.network.vpc_id
  alb_subnet_ids         = module.network.public_subnet_ids
  compute_subnet_id      = module.network.compute_subnet_id
  alb_sg_id              = module.network.alb_sg_id
  private_services_sg_id = module.network.private_services_sg_id
  app_port_range         = var.app_port_range

  rds_secret_read_policy_arn            = module.data.rds_secret_read_policy_arn
  core_sqs_produce_policy_arn           = module.data.core_sqs_produce_policy_arn
  worker_sqs_access_policy_arn          = module.data.worker_sqs_access_policy_arn
  app_config_read_policy_arn            = module.data.app_config_read_policy_arn
  jwt_secret_read_policy_arn            = module.data.jwt_secret_read_policy_arn
  mongodb_uri_secret_read_policy_arn    = module.data.mongodb_uri_secret_read_policy_arn
  groq_ai_secret_read_policy_arn        = module.data.groq_ai_secret_read_policy_arn
  nvidia_ai_secret_read_policy_arn      = module.data.nvidia_ai_secret_read_policy_arn
  gemini_ai_secret_read_policy_arn      = module.data.gemini_ai_secret_read_policy_arn
  open_router_ai_secret_read_policy_arn = module.data.open_router_ai_secret_read_policy_arn
  cloudinary_api_secret_read_policy_arn = module.data.cloudinary_api_secret_read_policy_arn
  opamp_auth_token_parameter_name       = var.grafana_cloud_opamp_auth_token_parameter_name
  opamp_endpoint_parameter_name         = module.observability.opamp_endpoint_parameter_name
  grafana_cloud_otlp_endpoint           = var.grafana_cloud_otlp_endpoint
  observability_read_policy_arn         = module.observability.observability_read_policy_arn
  otlp_write_key_parameter_name         = var.grafana_cloud_otlp_write_key_parameter_name


  app_deployments_read_policy_arn = module.deploy.app_deployments_read_policy_arn
}


module "observability" {
  source = "../../modules/observability"

  name_prefix                                   = var.name_prefix
  grafana_cloud_opamp_auth_token_parameter_name = var.grafana_cloud_opamp_auth_token_parameter_name
  grafana_cloud_opamp_endpoint                  = var.grafana_cloud_opamp_endpoint
  grafana_cloud_otlp_write_key_parameter_name   = var.grafana_cloud_otlp_write_key_parameter_name
}

module "lambda" {
  source = "../../modules/lambda"

  name_prefix = var.name_prefix

  firebase_credentials_secret_name = var.firebase_credentials_secret_name
  compute_subnet_id                = module.network.compute_subnet_id
  lambda_sg_id                     = module.network.lambda_sg_id

  notification_events_queue_arn = module.data.notification_events_queue_arn
  lambda_sqs_consume_policy_arn = module.data.lambda_sqs_consume_policy_arn
  rds_secret_read_policy_arn    = module.data.rds_secret_read_policy_arn
  app_config_read_policy_arn    = module.data.app_config_read_policy_arn
  observability_read_policy_arn = module.observability.observability_read_policy_arn

}

module "deploy" {
  source = "../../modules/deploy"

  name_prefix = var.name_prefix

  github_org   = var.github_org
  github_repos = var.github_repos

  lambda_function_arn           = module.lambda.function_arn
  lambda_deployments_bucket_arn = module.lambda.deployments_bucket_arn
  github_repo_env_name          = var.github_repo_env_name
}
