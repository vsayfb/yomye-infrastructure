resource "aws_iam_role" "core_chat" {
  name = "${local.name_prefix}-core-chat-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "core_chat_sqs_produce" {
  role       = aws_iam_role.core_chat.name
  policy_arn = var.core_sqs_produce_policy_arn
}

resource "aws_iam_role_policy_attachment" "core_chat_rds_secret" {
  role       = aws_iam_role.core_chat.name
  policy_arn = var.rds_secret_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "core_chat_observability_read" {
  role       = aws_iam_role.core_chat.name
  policy_arn = var.observability_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "cloudinary_api_secret_read" {
  role       = aws_iam_role.core_chat.name
  policy_arn = var.cloudinary_api_secret_read_policy_arn
}

resource "aws_iam_instance_profile" "core_chat" {
  name = "${local.name_prefix}-core-chat-profile"
  role = aws_iam_role.core_chat.name
}

resource "aws_iam_role" "worker" {
  name = "${local.name_prefix}-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "worker_sqs_access" {
  role       = aws_iam_role.worker.name
  policy_arn = var.worker_sqs_access_policy_arn
}

resource "aws_iam_role_policy_attachment" "worker_rds_secret" {
  role       = aws_iam_role.worker.name
  policy_arn = var.rds_secret_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "worker_observability_read" {
  role       = aws_iam_role.worker.name
  policy_arn = var.observability_read_policy_arn
}

resource "aws_iam_instance_profile" "worker" {
  name = "${local.name_prefix}-worker-profile"
  role = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "groq_ai_secret_read" {
  role       = aws_iam_role.worker.name
  policy_arn = var.groq_ai_secret_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "gemini_ai_secret_read" {
  role       = aws_iam_role.worker.name
  policy_arn = var.gemini_ai_secret_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "qwen_ai_secret_read" {
  role       = aws_iam_role.worker.name
  policy_arn = var.qwen_ai_secret_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "nvidia_ai_secret_read" {
  role       = aws_iam_role.worker.name
  policy_arn = var.nvidia_ai_secret_read_policy_arn
}


resource "aws_iam_role_policy_attachment" "core_chat_app_deployments_read" {
  role       = aws_iam_role.core_chat.name
  policy_arn = var.app_deployments_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "core_chat_ssm_managed_instance" {
  role       = aws_iam_role.core_chat.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "worker_app_deployments_read" {
  role       = aws_iam_role.worker.name
  policy_arn = var.app_deployments_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "worker_ssm_managed_instance" {
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "core_chat_app_config_read" {
  role       = aws_iam_role.core_chat.name
  policy_arn = var.app_config_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "core_chat_jwt_secret_read" {
  role       = aws_iam_role.core_chat.name
  policy_arn = var.jwt_secret_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "worker_app_config_read" {
  role       = aws_iam_role.worker.name
  policy_arn = var.app_config_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "chat_mongo_uri_secret_read" {
  role       = aws_iam_role.core_chat.name
  policy_arn = var.mongodb_uri_secret_read_policy_arn
}
