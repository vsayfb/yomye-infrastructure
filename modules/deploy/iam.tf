provider "github" {
  owner = var.github_org
}

data "github_user" "owner" {
  username = var.github_org
}

data "github_repository" "repos" {
  for_each  = toset(var.github_repos)
  full_name = "${var.github_org}/${each.value}"
}

locals {
  github_sub_conditions = flatten([
    for repo in data.github_repository.repos : [
      # Repositories using GitHub's legacy/default subject format.
      "repo:${var.github_org}/${repo.name}:environment:${var.github_repo_env_name}",

      # Repositories created after GitHub's immutable-subject rollout or
      # repositories that explicitly opted in to immutable subject claims.
      "repo:${var.github_org}@${data.github_user.owner.id}/${repo.name}@${repo.repo_id}:environment:${var.github_repo_env_name}",
    ]
  ])
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = local.common_tags
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "${local.name_prefix}-github-actions-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = local.github_sub_conditions
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "${local.name_prefix}-github-actions-deploy-policy"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "UploadArtifact"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.app_deployments.arn}/*"
      },
      {
        Sid    = "RunDeployCommand"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ]
        Resource = "*"
      },
      {
        Sid    = "DescribeInstances"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "UploadLambdaArtifact"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${var.lambda_deployments_bucket_arn}/*"
      },
      {
        Sid    = "DeployLambdaCode"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = var.lambda_function_arn
      }
    ]
  })
}

resource "aws_iam_policy" "app_deployments_read" {
  name        = "${local.name_prefix}-app-deployments-read"
  description = "Read-only access to the CodeDeploy app deployment artifacts bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ]
        Resource = "${aws_s3_bucket.app_deployments.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.app_deployments.arn
      }
    ]
  })

  tags = local.common_tags
}
