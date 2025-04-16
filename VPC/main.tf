terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Ensure we only use 2 AZs even if more are available in the region
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Merge default tags with environment-specific tags
  common_tags = merge(
    {
      Environment = var.environment
      Project     = "GameDayPrep"
      ManagedBy   = "Terraform"
    },
    var.tags # Allows overriding or adding tags via variables
  )
}

module "network" {
  source = "./modules/network"

  environment_name    = var.environment
  vpc_cidr            = var.vpc_cidr
  azs                 = local.azs
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs= var.private_subnet_cidrs
  tags                = local.common_tags
}

module "security" {
  source = "./modules/security"

  environment_name = var.environment
  vpc_id           = module.network.vpc_id
  bastion_ssh_cidr = var.bastion_ssh_cidr
  alb_ingress_cidr = var.alb_ingress_cidr
  tags             = local.common_tags
}

module "load_balancer" {
  source = "./modules/load_balancer"

  environment_name = var.environment
  vpc_id           = module.network.vpc_id
  public_subnet_ids= module.network.public_subnet_ids
  alb_sg_id        = module.security.alb_sg_id
  tags             = local.common_tags
}

module "compute" {
  source = "./modules/compute"

  environment_name       = var.environment
  vpc_id                 = module.network.vpc_id
  private_subnet_ids     = module.network.private_subnet_ids
  public_subnet_ids      = module.network.public_subnet_ids # For Bastion
  ec2_sg_id              = module.security.ec2_sg_id
  bastion_sg_id          = module.security.bastion_sg_id
  alb_sg_id              = module.security.alb_sg_id # Needed for EC2 SG rule
  target_group_arn       = module.load_balancer.target_group_arn
  instance_type          = var.instance_type
  game_day_ami_id        = var.game_day_ami_id
  asg_desired_capacity   = var.asg_desired_capacity
  asg_min_size           = var.asg_min_size
  asg_max_size           = var.asg_max_size
  ssh_key_name           = var.ssh_key_name
  aws_region             = var.aws_region # Needed for finding Ubuntu AMI
  tags                   = local.common_tags
} 