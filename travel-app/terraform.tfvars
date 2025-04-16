# Default variables for terraform.tfvars
# These can be overridden by environment-specific tfvars files (dev.tfvars, uat.tfvars, prod.tfvars)

# aws_region = "us-east-1"
# vpc_cidr = "10.0.0.0/16"
# public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
# private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
# instance_type = "t3.micro"
# bastion_ssh_cidr = ["YOUR_IP_ADDRESS/32"] # Recommended: Restrict access

# ssh_key_name = "your-default-key-pair-name" # MUST be provided if not set in env-specific files

# You MUST provide a value for ssh_key_name in one of the tfvars files being used.
# You likely also want to set 'environment' in your env-specific files,
# although it's not strictly required by the root variables (it's passed to modules).

# Example of a minimal terraform.tfvars if using env-specific files primarily:
ssh_key_name = "lx-mac-con-key"
# bastion_ssh_cidr = ["x.x.x.x/32"] 