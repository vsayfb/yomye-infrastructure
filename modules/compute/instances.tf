data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-20*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  remote_deploy_script_b64 = base64encode(
    file("${path.module}/scripts/remote-deploy.sh")
  )

  bootstrap_vars_base = {
    aws_region                      = var.aws_region
    opamp_endpoint_parameter_name   = var.opamp_endpoint_parameter_name
    opamp_auth_token_parameter_name = var.opamp_auth_token_parameter_name
    otlp_write_key_parameter_name   = var.otlp_write_key_parameter_name
    otel_collector_version          = var.otel_collector_version
    remote_deploy_script_b64        = local.remote_deploy_script_b64
  }
}

resource "aws_instance" "core_chat" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.core_chat_instance_type
  subnet_id              = var.compute_subnet_id
  vpc_security_group_ids = [var.private_services_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.core_chat.name

  user_data = templatefile(
    "${path.module}/scripts/bootstrap.sh.tpl",
    merge(
      local.bootstrap_vars_base,
      {
        service_name = "core-chat"
      }
    )
  )

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-core-chat"
    Service = "core-chat"
  })
}

resource "aws_instance" "worker" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.worker_instance_type
  subnet_id              = var.compute_subnet_id
  vpc_security_group_ids = [var.private_services_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.worker.name

  user_data = templatefile(
    "${path.module}/scripts/worker_bootstrap.sh.tpl",
    merge(
      local.bootstrap_vars_base,
      {
        service_name = "worker"
      }
    )
  )

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-worker"
    Service = "worker"
  })
}
