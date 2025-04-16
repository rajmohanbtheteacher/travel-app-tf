# Travel App Infrastructure

This repository contains the Terraform configuration for deploying the infrastructure of the Travel App on AWS. The infrastructure is modularized and supports multiple environments (e.g., dev, uat, prod).

## Architecture Overview

The infrastructure is designed with the following components:

1. **VPC and Subnets**:
   - A Virtual Private Cloud (VPC) with public and private subnets.
   - Public subnets for the Application Load Balancer (ALB) and Bastion host.
   - Private subnets for application servers.

2. **Security**:
   - Security groups to control access to resources.
   - Bastion host for secure SSH access to private instances.

3. **Load Balancer**:
   - An Application Load Balancer (ALB) to distribute traffic to application servers.

4. **Compute**:
   - EC2 instances managed by an Auto Scaling Group (ASG) for high availability.

## Architecture Diagram

Below is a textual representation of the architecture:

```
+---------------------------+
|        Internet           |
+---------------------------+
            |
            v
+---------------------------+
|    Application Load       |
|        Balancer (ALB)     |
+---------------------------+
            |
            v
+---------------------------+
|        Public Subnets     |
+---------------------------+
            |
            v
+---------------------------+
|        Private Subnets    |
|  (Application Servers in  |
|   Auto Scaling Group)     |
+---------------------------+
            |
            v
+---------------------------+
|        VPC                |
+---------------------------+
```

## Modules

The infrastructure is divided into the following modules:

1. **Network**:
   - Creates the VPC, public, and private subnets.
   - Outputs VPC ID and subnet IDs.

2. **Security**:
   - Configures security groups for ALB, EC2 instances, and Bastion host.

3. **Load Balancer**:
   - Deploys an ALB and associates it with public subnets.

4. **Compute**:
   - Launches EC2 instances in private subnets.
   - Configures an Auto Scaling Group (ASG).

## Variables

Key variables used in the configuration:

- `aws_region`: AWS region to deploy resources.
- `vpc_cidr`: CIDR block for the VPC.
- `public_subnet_cidrs`: CIDR blocks for public subnets.
- `private_subnet_cidrs`: CIDR blocks for private subnets.
- `instance_type`: EC2 instance type.
- `asg_desired_capacity`: Desired number of instances in the ASG.

## Outputs

Key outputs from the configuration:

- `alb_dns_name`: DNS name of the Application Load Balancer.
- `bastion_public_ip`: Public IP address of the Bastion host.
- `vpc_id`: ID of the created VPC.
- `public_subnet_ids`: IDs of the public subnets.
- `private_subnet_ids`: IDs of the private subnets.

## Usage

1. Clone the repository.
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Plan the deployment:
   ```bash
   terraform plan -var-file=<environment>.tfvars
   ```
4. Apply the configuration:
   ```bash
   terraform apply -var-file=<environment>.tfvars
   ```

Replace `<environment>` with `dev`, `uat`, or `prod` as needed.

## Notes

- Ensure you have the necessary AWS credentials configured.
- Review and update the `terraform.tfvars` file for environment-specific values.