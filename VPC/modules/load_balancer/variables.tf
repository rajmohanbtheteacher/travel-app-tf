variable "environment_name" {
  description = "Name of the environment (e.g., dev, uat, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ID of the security group to attach to the ALB"
  type        = string
}

variable "health_check_path" {
  description = "Path for the ALB target group health check"
  type        = string
  default     = "/" # Default to root path, adjust if needed
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
} 