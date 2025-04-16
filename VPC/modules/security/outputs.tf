output "alb_sg_id" {
  description = "The ID of the Application Load Balancer security group"
  value       = aws_security_group.alb.id
}

output "ec2_sg_id" {
  description = "The ID of the EC2 instances security group"
  value       = aws_security_group.ec2.id
}

output "bastion_sg_id" {
  description = "The ID of the Bastion host security group"
  value       = aws_security_group.bastion.id
} 