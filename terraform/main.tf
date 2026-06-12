# ---------------------------------------------------------------------------
# NOTE: NAT Gateway and its EIP are commented out for the initial apply to
# avoid hourly charges during early testing. Private subnet has no internet
# route until these are re-enabled in Phase 2 (needed for Ansible to reach
# package repositories from the app server).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Provider
# Tells Terraform we're targeting AWS and which region to use
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Use any 5.x version — the ~> means "compatible with"
    }
  }
}

provider "aws" {
  region = var.aws_region  # Pulls from variables.tf — "us-east-1"
}

# ---------------------------------------------------------------------------
# Hub VPC
# The central VPC — bastion and NAT gateway live here
# All traffic from the spoke routes through here to reach the internet
# ---------------------------------------------------------------------------

resource "aws_vpc" "hub" {
  cidr_block           = var.hub_vpc_cidr  # 10.0.0.0/16
  enable_dns_hostnames = true  # Allows EC2 instances to get DNS names
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-hub-vpc"  # "network-lab-hub-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# Hub Subnets
# ---------------------------------------------------------------------------

resource "aws_subnet" "hub_public" {
  vpc_id                  = aws_vpc.hub.id  # References the hub VPC above
  cidr_block              = var.hub_public_subnet_cidr  # 10.0.1.0/24
  availability_zone       = "${var.aws_region}a"  # us-east-1a
  map_public_ip_on_launch = true  # Instances here get a public IP automatically

  tags = {
    Name        = "${var.project_name}-hub-public-subnet"
    Environment = var.environment
    Project     = var.project_name
    Tier        = "public"  # Extra tag — makes the tier immediately readable in console
  }
}

resource "aws_subnet" "hub_private" {
  vpc_id            = aws_vpc.hub.id
  cidr_block        = var.hub_private_subnet_cidr  # 10.0.2.0/24
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "${var.project_name}-hub-private-subnet"
    Environment = var.environment
    Project     = var.project_name
    Tier        = "private"
  }
}

# ---------------------------------------------------------------------------
# Spoke VPC
# Simulates an isolated workload environment — app server lives here
# In a real environment this might be a separate account or business unit
# ---------------------------------------------------------------------------

resource "aws_vpc" "spoke" {
  cidr_block           = var.spoke_vpc_cidr  # 10.1.0.0/16
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-spoke-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# Spoke Subnet
# ---------------------------------------------------------------------------

resource "aws_subnet" "spoke_private" {
  vpc_id            = aws_vpc.spoke.id
  cidr_block        = var.spoke_private_subnet_cidr  # 10.1.2.0/24
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "${var.project_name}-spoke-private-subnet"
    Environment = var.environment
    Project     = var.project_name
    Tier        = "private"
  }
}

# ---------------------------------------------------------------------------
# Internet Gateway
# Attaches to the hub VPC — this is the on/off ramp to the internet
# Only the hub needs one; the spoke reaches out via the hub
# ---------------------------------------------------------------------------

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# Elastic IP for NAT Gateway
# NAT gateway needs a static public IP — this reserves one
# ---------------------------------------------------------------------------

# resource "aws_eip" "nat" {
#   domain = "vpc"  # Required for VPC-scoped EIPs in modern AWS provider versions

#   tags = {
#     Name        = "${var.project_name}-nat-eip"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }

# ---------------------------------------------------------------------------
# NAT Gateway
# Sits in the PUBLIC subnet — allows private subnet instances to reach
# the internet for updates etc., without being directly reachable from outside
# This is why the NAT goes in the public subnet, not the private one
# ---------------------------------------------------------------------------

# resource "aws_nat_gateway" "hub" {
#   allocation_id = aws_eip.nat.id          # The EIP we just reserved
#   subnet_id     = aws_subnet.hub_public.id  # Must be in the PUBLIC subnet

#   tags = {
#     Name        = "${var.project_name}-nat-gw"
#     Environment = var.environment
#     Project     = var.project_name
#   }

#   depends_on = [aws_internet_gateway.hub]
#   # depends_on tells Terraform to wait for the IGW to exist before creating
#   # the NAT gateway — even though there's no direct reference between them,
#   # the IGW must be attached for internet routing to work
# }

# ---------------------------------------------------------------------------
# Route Tables
# ---------------------------------------------------------------------------

# Public route table — sends internet-bound traffic to the IGW
resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id

  # route {
  #   cidr_block = "0.0.0.0/0"                    # All internet traffic
  #   gateway_id = aws_internet_gateway.hub.id     # Goes out through the IGW
  # }

  tags = {
    Name        = "${var.project_name}-hub-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Private route table — sends internet-bound traffic to the NAT gateway
resource "aws_route_table" "hub_private" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hub.id  # Goes out through NAT, not IGW directly
  }

  tags = {
    Name        = "${var.project_name}-hub-private-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Spoke route table — no internet route intentionally
# Spoke traffic stays internal — only reaches hub via peering
resource "aws_route_table" "spoke_private" {
  vpc_id = aws_vpc.spoke.id

  tags = {
    Name        = "${var.project_name}-spoke-private-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# Route Table Associations
# Links each subnet to its route table
# Without this, subnets use the VPC's default route table
# ---------------------------------------------------------------------------

resource "aws_route_table_association" "hub_public" {
  subnet_id      = aws_subnet.hub_public.id
  route_table_id = aws_route_table.hub_public.id
}

resource "aws_route_table_association" "hub_private" {
  subnet_id      = aws_subnet.hub_private.id
  route_table_id = aws_route_table.hub_private.id
}

resource "aws_route_table_association" "spoke_private" {
  subnet_id      = aws_subnet.spoke_private.id
  route_table_id = aws_route_table.spoke_private.id
}

# ---------------------------------------------------------------------------
# VPC Peering
# Creates the logical connection between hub and spoke
# Think of it like a virtual patch cable between the two VPCs
# ---------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "hub_to_spoke" {
  vpc_id      = aws_vpc.hub.id    # Requester
  peer_vpc_id = aws_vpc.spoke.id  # Accepter
  auto_accept = true              # Works because both VPCs are in the same account

  tags = {
    Name        = "${var.project_name}-hub-spoke-peering"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------
# Peering Routes
# The peering connection exists but traffic won't flow until both sides
# have routes pointing at each other through the peering connection
# This is the equivalent of adding static routes on both ends of a circuit
# ---------------------------------------------------------------------------

# Hub side — tells hub how to reach the spoke
resource "aws_route" "hub_to_spoke" {
  route_table_id            = aws_route_table.hub_private.id
  destination_cidr_block    = var.spoke_vpc_cidr  # 10.1.0.0/16
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_spoke.id
}

# Spoke side — tells spoke how to reach the hub
resource "aws_route" "spoke_to_hub" {
  route_table_id            = aws_route_table.spoke_private.id
  destination_cidr_block    = var.hub_vpc_cidr  # 10.0.0.0/16
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_to_spoke.id
}