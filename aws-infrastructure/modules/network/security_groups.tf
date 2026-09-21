resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB - allows inbound HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

resource "aws_security_group_rule" "alb_egress_to_private_services" {
  description              = "App traffic to Core/Chat"
  type                     = "egress"
  from_port                = var.app_port_range.from
  to_port                  = var.app_port_range.to
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.private_services.id
}

resource "aws_security_group" "nat" {
  name        = "${local.name_prefix}-nat-sg"
  description = "NAT instance - outbound Internet access for private subnets."
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-sg"
  })
}

resource "aws_security_group_rule" "nat_egress_all" {
  description       = "Unrestricted outbound - forwards traffic to the internet"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nat.id
}

resource "aws_security_group" "private_services" {
  name        = "${local.name_prefix}-private-services-sg"
  description = "Security group for private application services"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-services-sg"
  })
}

resource "aws_security_group_rule" "private_services_ingress_from_alb" {
  description              = "App traffic from ALB"
  type                     = "ingress"
  from_port                = var.app_port_range.from
  to_port                  = var.app_port_range.to
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_services.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "private_services_egress_https" {
  description       = "HTTPS out - SQS API, Groq, MongoDB Atlas, Grafana Cloud"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private_services.id
}

resource "aws_security_group_rule" "private_services_egress_mongodb_atlas" {
  description       = "MongoDB Atlas outbound"
  type              = "egress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private_services.id
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS Postgres - reachable only from Core/Chat/Worker"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-sg"
  })
}

resource "aws_security_group_rule" "nat_ingress_from_private" {
  description              = "All traffic from private application services"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.nat.id
  source_security_group_id = aws_security_group.private_services.id
}

resource "aws_security_group_rule" "nat_ingress_from_lambda" {
  description              = "Forward HTTPS traffic from Notification Lambda"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nat.id
  source_security_group_id = aws_security_group.lambda.id
}

resource "aws_security_group_rule" "rds_ingress_from_private" {
  description              = "Postgres from Core/Chat/Worker"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.private_services.id
}

resource "aws_security_group_rule" "private_services_egress_postgres" {
  description              = "Postgres out to RDS"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_services.id
  source_security_group_id = aws_security_group.rds.id
}

resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Notification Lambda - VPC-attached, egress-only (RDS + Firebase via NAT)"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-sg"
  })
}

resource "aws_security_group_rule" "lambda_egress_rds" {
  description              = "Postgres to RDS"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda.id
  source_security_group_id = aws_security_group.rds.id
}

resource "aws_security_group_rule" "lambda_egress_https" {
  description       = "HTTPS out - Firebase push"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda.id
}

resource "aws_security_group_rule" "rds_ingress_from_lambda" {
  description              = "Postgres from Notification Lambda"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.lambda.id
}
