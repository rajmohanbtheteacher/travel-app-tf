# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-vpc"
    }
  )
}

locals {
  # Create maps where the key is the AZ and the value is the CIDR
  # Assumption: The order of var.azs matches the order of the CIDR lists
  public_subnets_map = zipmap(var.azs, var.public_subnet_cidrs)
  private_subnets_map = zipmap(var.azs, var.private_subnet_cidrs)
}

# --- Subnets ---
resource "aws_subnet" "public" {
  # Use for_each to iterate over the map
  for_each                = local.public_subnets_map
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value # Get CIDR from map value
  availability_zone       = each.key   # Get AZ from map key
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      # Use the AZ (each.key) for more semantic naming
      Name        = "${var.environment_name}-public-subnet-${each.key}"
      Tier        = "Public"
      AZ          = each.key
    }
  )
}

resource "aws_subnet" "private" {
  # Use for_each to iterate over the map
  for_each          = local.private_subnets_map
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value # Get CIDR from map value
  availability_zone = each.key   # Get AZ from map key

  tags = merge(
    var.tags,
    {
      # Use the AZ (each.key) for more semantic naming
      Name        = "${var.environment_name}-private-subnet-${each.key}"
      Tier        = "Private"
      AZ          = each.key
    }
  )
}

# --- Gateways ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-igw"
    }
  )
}

# NAT Gateway needs an Elastic IP
resource "aws_eip" "nat" {
  # Conditionally create EIP only if there are private subnets requiring NAT
  count = length(var.private_subnet_cidrs) > 0 ? 1 : 0 
  domain   = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "nat" {
  # Conditionally create NAT only if EIP is created.
  # Place in the public subnet of the *first* AZ from the input list for consistency.
  count         = length(aws_eip.nat) > 0 ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[var.azs[0]].id # Reference public subnet using the first AZ key

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-nat-gw"
    }
  )

  # Ensure IGW is created before NAT GW
  depends_on = [aws_internet_gateway.igw]
}

# --- Route Tables ---
# Public Route Table (routes to IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-public-rt"
    }
  )
}

# Private Route Table (routes to NAT GW)
resource "aws_route_table" "private" {
  # Conditionally create private RT only if NAT GW is created
  count  = length(aws_nat_gateway.nat) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment_name}-private-rt"
    }
  )
}

# --- Route Table Associations ---
# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  # Use for_each over the created public subnets
  for_each       = aws_subnet.public
  subnet_id      = each.value.id # Get ID from the subnet object
  route_table_id = aws_route_table.public.id
}

# Associate Private Subnets with Private Route Table (if it exists)
resource "aws_route_table_association" "private" {
  # Use for_each only if the private route table exists
  for_each       = length(aws_route_table.private) > 0 ? aws_subnet.private : {}
  subnet_id      = each.value.id # Get ID from the subnet object
  route_table_id = aws_route_table.private[0].id
} 