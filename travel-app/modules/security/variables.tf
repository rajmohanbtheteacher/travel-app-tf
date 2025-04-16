variable "environment_name" {
  description = "Name of the environment (e.g., dev, uat, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "bastion_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into the Bastion host"
  type        = list(string)
}

variable "alb_ingress_cidr" {
  description = "CIDR blocks allowed to access the ALB on HTTP/HTTPS"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
} 