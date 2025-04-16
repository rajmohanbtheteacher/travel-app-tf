variable "environment_name" {
  description = "Name of the environment (e.g., dev, uat, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ASG"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (needed for Bastion host)"
  type        = list(string)
}

variable "ec2_sg_id" {
  description = "ID of the security group for the application EC2 instances"
  type        = string
}

variable "bastion_sg_id" {
  description = "ID of the security group for the Bastion host"
  type        = string
}

variable "alb_sg_id" {
  description = "ID of the ALB security group (needed for EC2 SG rule reference in some potential configurations, though explicitly defined in security module)"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB Target Group to associate with the ASG"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for application and bastion hosts"
  type        = string
}

variable "game_day_ami_id" {
  description = "AMI ID for the Game Day application EC2 instances"
  type        = string
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
}

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "aws_region" {
  description = "AWS region (used to find Ubuntu AMI)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
} 