# --- Find latest Ubuntu 22.04 LTS AMI for Bastion ---
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical's Owner ID
}

# --- Launch Template for Application Instances ---
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment_name}-app-"
  image_id      = var.game_day_ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  network_interfaces {
    associate_public_ip_address = false # Instances are in private subnets
    security_groups             = [var.ec2_sg_id]
  }

  # Add user data if needed (e.g., install web server, configure app)
  # user_data = base64encode(file("${path.module}/user_data.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.environment_name}-app-instance"
      }
    )
  }
  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${var.environment_name}-app-volume"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-app-lt"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# --- Auto Scaling Group for Application Instances ---
resource "aws_autoscaling_group" "app" {
  name_prefix               = "${var.environment_name}-asg-"
  vpc_zone_identifier       = var.private_subnet_ids
  desired_capacity          = var.asg_desired_capacity
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  health_check_type         = "ELB"
  health_check_grace_period = 300 # Give instances time to start before ELB checks
  target_group_arns         = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Ensure instances are terminated before the ASG is deleted during destroy
  force_delete = true

  # Use suspended_processes if needed during updates
  # suspended_processes = ["Terminate", "ReplaceUnhealthy"]

  # Define tags using individual blocks for propagation
  tag {
    key                 = "Name"
    value               = "${var.environment_name}-app-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment_name
    propagate_at_launch = true
  }

  # Propagate common tags if they exist
  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [desired_capacity] # Often managed outside TF (e.g., scaling policies)
  }
}

# --- Bastion Host Instance ---
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type # Using same type as app for simplicity, adjust if needed
  key_name      = var.ssh_key_name

  # Place bastion in the first public subnet
  subnet_id                   = var.public_subnet_ids[0]
  associate_public_ip_address = true # Needs public IP to be reachable
  vpc_security_group_ids      = [var.bastion_sg_id]

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-bastion-host"
    }
  )
} 