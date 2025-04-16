# --- ALB Security Group ---
resource "aws_security_group" "alb" {
  name        = "${var.environment_name}-alb-sg"
  description = "Allow HTTP/HTTPS inbound traffic to ALB"
  vpc_id      = var.vpc_id

  # Allow HTTP from specified CIDRs (e.g., 0.0.0.0/0)
  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.alb_ingress_cidr
  }

  # Allow HTTPS from specified CIDRs (Optional, but good practice)
  # ingress {
  #   description      = "HTTPS from anywhere"
  #   from_port        = 443
  #   to_port          = 443
  #   protocol         = "tcp"
  #   cidr_blocks      = var.alb_ingress_cidr
  # }

  # Allow all outbound traffic
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # -1 signifies all protocols
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-alb-sg"
    }
  )
}

# --- Bastion Host Security Group ---
resource "aws_security_group" "bastion" {
  name        = "${var.environment_name}-bastion-sg"
  description = "Allow SSH inbound traffic to Bastion host"
  vpc_id      = var.vpc_id

  # Allow SSH from specified CIDRs (e.g., your IP / 0.0.0.0/0)
  ingress {
    description      = "SSH from specified CIDRs"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_ssh_cidr
  }

  # Allow all outbound traffic (needed for SSH proxying and updates)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-bastion-sg"
    }
  )
}

# --- EC2 Instance Security Group ---
resource "aws_security_group" "ec2" {
  name        = "${var.environment_name}-ec2-sg"
  description = "Allow traffic from ALB and Bastion to EC2 instances"
  vpc_id      = var.vpc_id

  # Allow HTTP (port 80) ONLY from the ALB Security Group
  ingress {
    description       = "HTTP from ALB"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    security_groups   = [aws_security_group.alb.id] # Reference ALB SG
  }

  # Allow SSH (port 22) ONLY from the Bastion Security Group
  ingress {
    description       = "SSH from Bastion"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    security_groups   = [aws_security_group.bastion.id] # Reference Bastion SG
  }

  # Allow all outbound traffic (for updates, talking to other AWS services, etc.)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-ec2-sg"
    }
  )
} 