variable "name_prefix" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  description = "Two Availability Zones to spread subnets across. Index 0 is where all real compute lives; index 1 exists only to satisfy ALB/RDS subnet-group AZ-count requirements."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs for the two public subnets, one per AZ. Index 0 hosts the NAT instance; index 1 is empty (ALB requirement only)."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for the two private subnets, one per AZ. Index 0 hosts Core+Chat and Worker; index 1 is empty (RDS subnet-group requirement only)."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "nat_instance_type" {
  description = "Instance type for the self-managed NAT instance."
  type        = string
  default     = "t3.micro"
}

variable "app_port_range" {
  description = "Port range on the private-services instance that the ALB is allowed to reach (Core HTTP + Chat WebSocket)."
  type = object({
    from = number
    to   = number
  })
  default = {
    from = 8080
    to   = 8081
  }
}

variable "tags" {
  description = "Common tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
