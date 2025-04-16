# AWS Game Day Preparation Infrastructure Documentation

## 1. Introduction

This document outlines the AWS infrastructure designed and deployed using Terraform for the Game Day preparation. The goal is to provide a scalable, resilient, and secure base environment for hosting a web application, replicated across multiple environments (Dev, UAT, Prod). Terraform enables Infrastructure as Code (IaC), ensuring consistency, reproducibility, and version control for the infrastructure setup.

## 2. Architecture Overview

The architecture follows standard AWS best practices, utilizing a Virtual Private Cloud (VPC) spread across two Availability Zones (AZs) for high availability. It employs a public/private subnet strategy to protect backend resources.

*   **Networking:** A custom VPC houses all resources. Public subnets host internet-facing resources like the Application Load Balancer (ALB) and the Bastion host. Private subnets host the application EC2 instances, preventing direct internet access. An Internet Gateway (IGW) allows communication between the VPC and the internet, while a NAT Gateway allows instances in private subnets to initiate outbound connections (e.g., for updates) without being directly reachable from the internet.
*   **Load Balancing:** An Application Load Balancer (ALB) distributes incoming HTTP traffic across the application instances running in the private subnets across both AZs. It serves as the single entry point for user traffic.
*   **Compute:** An Auto Scaling Group (ASG) manages the application EC2 instances based on a Launch Template. This ensures the desired number of instances are running (min 2, desired 2, max 6) and automatically replaces unhealthy instances. The Launch Template specifies the Game Day application AMI (`ami-09c918c6f7ecc32ef`). A separate Bastion host (Ubuntu 22.04) is provisioned in a public subnet for secure administrative SSH access to the private instances.
*   **Security:** Security Groups act as virtual firewalls controlling traffic flow:
    *   ALB Security Group allows inbound HTTP/HTTPS traffic from the internet.
    *   EC2 Instance Security Group allows inbound HTTP traffic *only* from the ALB and inbound SSH traffic *only* from the Bastion host.
    *   Bastion Host Security Group allows inbound SSH traffic *only* from specified user IP addresses.
*   **Environments:** The entire stack is designed to be deployed independently for `dev`, `uat`, and `prod` environments using Terraform workspaces and variable files (`.tfvars`).

## 3. Terraform Code Structure

The Terraform code is organized using a modular approach to promote reusability, maintainability, and separation of concerns.

*   **Root Directory:**
    *   `main.tf`: Defines the Terraform settings (required version, providers), configures the AWS provider, fetches Availability Zone data, defines local variables (like common tags, selected AZs), and calls the child modules, passing necessary variables and wiring outputs to inputs.
    *   `variables.tf`: Declares input variables used by the root module and passed down to child modules (e.g., `aws_region`, `environment`, `vpc_cidr`, `instance_type`, `ssh_key_name`). Defines defaults where appropriate.
    *   `outputs.tf`: Defines outputs exposed after a successful apply (e.g., `alb_dns_name`, `bastion_public_ip`).
    *   `terraform.tfvars`: Contains default values for variables. **Note:** Sensitive or required variables like `ssh_key_name` should ideally be set here or, preferably, in environment-specific files.
    *   `dev.tfvars`, `uat.tfvars`, `prod.tfvars`: Environment-specific variable overrides. These files allow customization (e.g., different CIDR blocks, instance types, or tags) per environment.

*   **`modules/` Directory:** Contains reusable child modules:
    *   **`network/`**: Responsible for creating the VPC, Subnets (using `for_each` over Availability Zones for semantic clarity), Internet Gateway, NAT Gateway (+ Elastic IP), and Route Tables/Associations.
    *   **`security/`**: Responsible for creating the Security Groups for the ALB, EC2 instances, and the Bastion host, including the specific ingress/egress rules linking them.
    *   **`load_balancer/`**: Responsible for creating the Application Load Balancer (ALB), Target Group (including health check configuration), and Listener(s).
    *   **`compute/`**: Responsible for finding the latest Ubuntu AMI (for Bastion), creating the EC2 Launch Template (using the specified Game Day AMI), the Auto Scaling Group (linking the LT, Target Group, and private subnets), and the Bastion host instance (in a public subnet). It uses a `dynamic "tag"` block to apply common tags to ASG instances.

*   **Key Terraform Features Used:**
    *   **Modules:** For code organization and reusability.
    *   **Variables & Outputs:** For parameterization and inter-module communication.
    *   **`.tfvars` Files:** For environment-specific configuration.
    *   **Workspaces:** For managing state isolation between environments.
    *   `for_each`: Used in the `network` module for creating subnets and route table associations based on Availability Zones, providing clearer references than `count`.
    *   `dynamic` Blocks: Used in the `compute` module to dynamically generate tag blocks for the ASG based on the common tags variable.
    *   **Data Sources:** Used to fetch current AZs and the latest Ubuntu AMI ID.
    *   **Resource Dependencies:** Implicit dependencies are handled by Terraform; explicit dependencies (`depends_on`) are used where necessary (e.g., NAT Gateway depends on IGW).

## 4. Deployment Workflow

1.  **Prerequisites:**
    *   Install Terraform.
    *   Configure AWS Credentials (e.g., via environment variables, shared credential file, or IAM role).
    *   Clone the Terraform code repository.
    *   **Customize `.tfvars`:** Edit `terraform.tfvars` and/or environment-specific files (`dev.tfvars`, `uat.tfvars`, `prod.tfvars`). **Crucially, you must provide the `ssh_key_name`** (matching an existing key pair in your target AWS region) and **should restrict the `bastion_ssh_cidr`** to your IP address. Adjust other variables (region, instance types, CIDRs) as needed per environment.

2.  **Initialization:** Navigate to the root directory of the Terraform project in your terminal and run:
    ```bash
    terraform init
    ```
    This downloads the AWS provider plugin and initializes modules.

3.  **Workspace Selection:** Use Terraform workspaces to isolate state for each environment.
    *   Create (if it doesn't exist) and select a workspace:
        ```bash
        # For Dev environment
        terraform workspace new dev || terraform workspace select dev

        # For UAT environment
        terraform workspace new uat || terraform workspace select uat

        # For Prod environment
        terraform workspace new prod || terraform workspace select prod
        ```
    *   Ensure you are in the correct workspace before planning or applying.

4.  **Plan:** Generate an execution plan to see what Terraform will create/modify/destroy. Use the appropriate `-var-file` for your selected environment.
    ```bash
    # Example for Dev
    terraform plan -var-file="dev.tfvars" | cat
    ```
    **Review this plan carefully.**

5.  **Apply:** If the plan is acceptable, apply the changes to build the infrastructure.
    ```bash
    # Example for Dev (with auto-approve)
    terraform apply -var-file="dev.tfvars" -auto-approve

    # Or without auto-approve (requires typing 'yes' at the prompt)
    terraform apply -var-file="dev.tfvars"
    ```

6.  **Output Review:** After applying, Terraform will display the defined outputs (ALB DNS name, Bastion IP).

7.  **Deploying Other Environments:** Repeat steps 3-5, selecting the appropriate workspace (`uat` or `prod`) and using the corresponding `-var-file` (`uat.tfvars` or `prod.tfvars`).

8.  **Destroy:** To tear down the infrastructure for a specific environment, select the correct workspace and run:
    ```bash
    # Example for Dev
    terraform destroy -var-file="dev.tfvars"
    ```
    Confirm by typing `yes`.

## 5. Architecture Diagram (Mermaid)

```mermaid
graph LR
    subgraph "AWS Region (us-east-1)"
        subgraph "VPC (dev-vpc)"
             direction TB

             IGW(fa:fa-cloud Internet Gateway)
             RT_Public(fa:fa-route Public Route Table <br> 0.0.0.0/0 --> IGW)
             RT_Private(fa:fa-route Private Route Table <br> 0.0.0.0/0 --> NAT)

             subgraph "Availability Zone A"
                 direction TB
                 subgraph "Public Subnet A" [PublicSubnetA]
                    %% Assign ID if needed
                    style PublicSubnetA fill:#fff0f7,stroke:#b43d81,rx:5,ry:5
                    ALBNodeA(fa:fa-cube ALB Node)
                    Bastion(fa:fa-laptop Bastion Host)
                    NAT(fa:fa-map-signs NAT Gateway) --- EIP(fa:fa-tag Elastic IP)
                 end
                 subgraph "Private Subnet A" [PrivateSubnetA]
                     %% Assign ID if needed
                    style PrivateSubnetA fill:#edf7ff,stroke:#317ab4,rx:5,ry:5
                    AppInstancesA(fa:fa-cubes EC2 Instances)
                 end
             end

             subgraph "Availability Zone B"
                  direction TB
                  subgraph "Public Subnet B" [PublicSubnetB]
                     %% Assign ID if needed
                     style PublicSubnetB fill:#fff0f7,stroke:#b43d81,rx:5,ry:5
                     ALBNodeB(fa:fa-cube ALB Node)
                  end
                  subgraph "Private Subnet B" [PrivateSubnetB]
                     %% Assign ID if needed
                     style PrivateSubnetB fill:#edf7ff,stroke:#317ab4,rx:5,ry:5
                     AppInstancesB(fa:fa-cubes EC2 Instances)
                  end
             end

             ALB(fa:fa-balance-scale Application <br> Load Balancer)
             TG(fa:fa-bullseye Target Group)
             ASG(fa:fa-sync Auto Scaling Group <br> Min:2, Max:6)
             LT(fa:fa-file-alt Launch Template)

             %% Associations using Subgraph IDs
             PublicSubnetA -- Assoc --> RT_Public
             PublicSubnetB -- Assoc --> RT_Public
             PrivateSubnetA -- Assoc --> RT_Private
             PrivateSubnetB -- Assoc --> RT_Private

             %% Routing & Traffic Flow
             RT_Public --> IGW
             ALB --- ALBNodeA
             ALB --- ALBNodeB
             ALB -- Forwards To --> TG

             TG -- Registers --> AppInstancesA
             TG -- Registers --> AppInstancesB

             ASG --- LT
             ASG -- Manages --> AppInstancesA
             ASG -- Manages --> AppInstancesB

             AppInstancesA -- Outbound --> RT_Private
             AppInstancesB -- Outbound --> RT_Private
             RT_Private --> NAT

             %% Security Groups
             SG_ALB(fa:fa-shield-alt SG: ALB <br> Allows HTTP In) --- ALB
             SG_EC2(fa:fa-shield-alt SG: EC2 <br> Allows HTTP from ALB <br> Allows SSH from Bastion)
             SG_Bastion(fa:fa-shield-alt SG: Bastion <br> Allows SSH In) --- Bastion

             SG_ALB -- Traffic to --> SG_EC2
             SG_Bastion -- Traffic to --> SG_EC2

             AppInstancesA --- SG_EC2
             AppInstancesB --- SG_EC2

        end
    end

    %% External Entities & Connections
    User(fa:fa-user User) --> Internet(fa:fa-globe Internet)
    Internet -- HTTP/HTTPS --> SG_ALB
    Internet --- IGW
    User -- SSH --> SG_Bastion

    %% Styling & Classes
    style PublicSubnetA fill:#fff0f7,stroke:#b43d81,rx:5,ry:5
    style PrivateSubnetA fill:#edf7ff,stroke:#317ab4,rx:5,ry:5
    style PublicSubnetB fill:#fff0f7,stroke:#b43d81,rx:5,ry:5
    style PrivateSubnetB fill:#edf7ff,stroke:#317ab4,rx:5,ry:5

    classDef default fill:#ffffff,stroke:#555,stroke-width:1px,rx:3,ry:3;
    class RT_Public,RT_Private,SG_ALB,SG_EC2,SG_Bastion fill:#fdfae3,stroke:#e8ad02;
    class ALB,TG,ASG,LT,Bastion,AppInstancesA,AppInstancesB,ALBNodeA,ALBNodeB fill:#d5f5e3,stroke:#27ae60;
    class IGW,NAT,EIP fill:#e8f8f5,stroke:#16a085;
    class Internet,User fill:#ebedef,stroke:#566573;
```

## 6. Conclusion

This Terraform project provides a robust and automated way to deploy the required AWS infrastructure for the Game Day preparation. By leveraging modules, variables, and workspaces, it offers a flexible, maintainable, and reproducible solution that adheres to common AWS best practices for security and availability. 