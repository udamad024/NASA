# Terraform Config file (main.tf). This has provider block (AWS) and config for provisioning one EC2 instance resource.  

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.27"
    }
  }

  required_version = ">=0.14"
}
provider "aws" {
#  profile = "default"
  region  = "us-east-1"
}

#ashgiasdasasa
# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

# Define tags locally
locals {
  default_tags = merge(var.default_tags, { "env" = var.env })
}

# Create a new VPC 
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = merge(
    local.default_tags, {
      Name = "VPC ${var.env}"
    }
  )
}

# Add provisioning of the public subnetin the default VPC
resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    local.default_tags, {
      Name = "Public-subnet-${count.index}"
    }
  )
}

resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    local.default_tags, {
      Name = "Private-subnet-${count.index}"
    }
  )
}


# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.default_tags,
    {
      "Name" = "${var.env}-igw"
    }
  )
}


# Route table to route add default gateway pointing to Internet Gateway (IGW)
resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.env}-route-public-subnets"
  }
}

# Associate subnets with the custom route table
resource "aws_route_table_association" "public_route_table_association" {
  count          = length(aws_subnet.public_subnet[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

# ...

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  vpc = true

  tags = merge(local.default_tags, {
    "Name" = "${var.env}-nat-gateway-eip"
  })
}

# NAT Gateway in the first public subnet
resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  # Depending on your configuration, you might want to enable/disable NAT gateway's public IP assignment
  # You would add `public_ip_assignment` attribute here according to your needs.

  tags = merge(local.default_tags, {
    "Name" = "${var.env}-nat-gateway"
  })
}

# Adjust your private route table to route non-local traffic to the NAT Gateway
resource "aws_route_table" "private_subnets" {
  vpc_id = aws_vpc.main.id

  route {
    # Remove the incorrect route that has the same CIDR as the VPC

    # This is the correct route for Internet-bound traffic from private subnets
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gateway.id
  }

  tags = merge(local.default_tags, {
    "Name" = "${var.env}-route-private-subnets"
  })
}


# Associate private subnets with the private route table
resource "aws_route_table_association" "private_route_table_association" {
  count         = length(aws_subnet.private_subnet[*].id)
  route_table_id = aws_route_table.private_subnets.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}

# ...