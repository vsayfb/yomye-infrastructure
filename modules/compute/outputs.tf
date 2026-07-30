output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "core_chat_instance_id" {
  value = aws_instance.core_chat.id
}

output "worker_instance_id" {
  value = aws_instance.worker.id
}

output "core_chat_instance_ip" {
  value = aws_instance.core_chat.private_ip
}

output "worker_instance_ip" {
  value = aws_instance.worker.private_ip
}


output "core_chat_role_arn" {
  value = aws_iam_role.core_chat.arn
}

output "worker_role_arn" {
  value = aws_iam_role.worker.arn
}

output "core_chat_role_name" {
  value = aws_iam_role.core_chat.name
}

output "worker_role_name" {
  value = aws_iam_role.worker.name
}
