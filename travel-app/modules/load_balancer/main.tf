# --- Application Load Balancer ---
resource "aws_lb" "main" {
  name               = "${var.environment_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false # Set to true for production environments if desired

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-alb"
    }
  )
}

# --- Target Group ---
# For the EC2 instances managed by the ASG
resource "aws_lb_target_group" "main" {
  name        = "${var.environment_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200" # Expect HTTP 200 for healthy instances
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-tg"
    }
  )
}

# --- Listener ---
# Listens on HTTP port 80 and forwards to the target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Optional: Add an HTTPS listener if you have a certificate
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08" # Choose appropriate policy
#   certificate_arn   = "arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERTIFICATE_ID" # Replace with your ACM cert ARN
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.main.arn
#   }
# } 