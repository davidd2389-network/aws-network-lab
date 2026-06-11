# ---------------------------------------------------------------------------
# General
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix all resource names and tags"
  type        = string
  default     = "network-lab"
}

variable "environment" {
  description = "Environment label applied to all resource tags"
  type        = string
  default     = "lab"
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "hub_vpc_cidr" {
  description = "CIDR block for the hub VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "hub_public_subnet_cidr" {
  description = "CIDR block for the hub public subnet (bastion lives here)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "hub_private_subnet_cidr" {
  description = "CIDR block for the hub private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "spoke_vpc_cidr" {
  description = "CIDR block for the spoke VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "spoke_private_subnet_cidr" {
  description = "CIDR block for the spoke private subnet"
  type        = string
  default     = "10.1.2.0/24"
}

# ---------------------------------------------------------------------------
# Access control
# ---------------------------------------------------------------------------

variable "your_home_ip" {
  description = "Your public IP in CIDR notation (e.g. 1.2.3.4/32) — restricts SSH to your machine only"
  type        = string
  # No default — this must be explicitly set in terraform.tfvars
  # /32 means exactly one IP address
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for bastion and app server"
  type        = string
  default     = "t2.micro"  # Free tier eligible
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to use for SSH access to EC2 instances"
  type        = string
  # No default — must be set in terraform.tfvars after you create the key pair in AWS
}