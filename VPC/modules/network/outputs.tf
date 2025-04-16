output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = [for subnet in values(aws_subnet.public) : subnet.id]
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  value       = [for subnet in values(aws_subnet.private) : subnet.id]
} 