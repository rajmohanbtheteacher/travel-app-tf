variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Or your preferred default region
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, uat, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (need 2)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Please provide exactly two public subnet CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (need 2)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Please provide exactly two private subnet CIDR blocks."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the application servers and bastion host"
  type        = string
  default     = "t3.micro"
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 6
}

variable "bastion_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into the Bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Consider restricting this to your IP
}

variable "alb_ingress_cidr" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "game_day_ami_id" {
  description = "AMI ID for the Game Day application EC2 instances"
  type        = string
  default     = "ami-09c918c6f7ecc32ef"
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair to use for SSH access (must exist in the target region)"
  type        = string
  # No default - user must provide this
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
} 