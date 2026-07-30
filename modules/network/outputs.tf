output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the two public subnets, in AZ order. Index 0 hosts the NAT instance."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the two private subnets, in AZ order. Index 0 hosts real compute; index 1 exists only for the RDS subnet group."
  value       = aws_subnet.private[*].id
}

output "compute_subnet_id" {
  description = "The single private subnet (AZ index 0) that Core/Chat and Worker instances should actually launch into."
  value       = aws_subnet.private[0].id
}

output "alb_subnet_ids" {
  description = "Convenience alias for the public subnet IDs, for wiring straight into the ALB's subnet_mapping."
  value       = aws_subnet.public[*].id
}

output "alb_sg_id" {
  description = "Security group ID for the ALB."
  value       = aws_security_group.alb.id
}

output "private_services_sg_id" {
  description = "Security group ID shared by Core, Chat, and the Categorization Worker."
  value       = aws_security_group.private_services.id
}

output "nat_sg_id" {
  description = "Security group ID for the NAT instance."
  value       = aws_security_group.nat.id
}

output "rds_sg_id" {
  description = "Security group ID for RDS."
  value       = aws_security_group.rds.id
}

output "nat_instance_id" {
  description = "Instance ID of the NAT instance (also the SSH jump box into the private subnet)."
  value       = aws_instance.nat.id
}

output "nat_instance_public_ip" {
  description = "Elastic IP of the NAT instance."
  value       = aws_eip.nat.public_ip
}

output "nat_instance_private_ip" {
  description = "Private IP of the NAT instance inside the VPC."
  value       = aws_instance.nat.private_ip
}

output "lambda_sg_id" {
  value = aws_security_group.lambda.id
}

