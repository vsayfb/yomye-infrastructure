locals {
  name_prefix = var.name_prefix
  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "compute"
  })
}

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.alb_subnet_ids
  idle_timeout       = var.alb_idle_timeout

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-alb" })
}

resource "aws_lb_target_group" "core" {
  name     = "${local.name_prefix}-core-tg"
  port     = var.core_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-core-tg" })
}

resource "aws_lb_target_group" "chat" {
  name     = "${local.name_prefix}-chat-tg"
  port     = var.chat_port
  protocol = "HTTP"

  vpc_id = var.vpc_id

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-chat-tg" })
}

resource "aws_lb_target_group_attachment" "core" {
  target_group_arn = aws_lb_target_group.core.arn
  target_id        = aws_instance.core_chat.id
  port             = var.core_port
}

resource "aws_lb_target_group_attachment" "chat" {
  target_group_arn = aws_lb_target_group.chat.arn
  target_id        = aws_instance.core_chat.id
  port             = var.chat_port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = local.common_tags
}

resource "aws_lb_listener_rule" "core" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = var.core_path_pattern
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core.arn
  }

  tags = local.common_tags
}

resource "aws_lb_listener_rule" "core_probes" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 90

  condition {
    path_pattern {
      values = [
        "/core/health",
        "/core/ready",
      ]
    }
  }

  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^/core/(health|ready)$"
        replace = "/$1"
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core.arn
  }

  tags = local.common_tags
}

resource "aws_lb_listener_rule" "chat" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  condition {
    path_pattern {
      values = [
        "/chat",
        "/chat/*",
      ]
    }
  }

  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^/chat/?(.*)$"
        replace = "/$1"
      }
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chat.arn
  }

  tags = local.common_tags
}
