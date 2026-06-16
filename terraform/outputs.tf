# ---------------------------------------------------------------------------
# VPC IDs
# Useful for referencing in the AWS console, or for future Terraform configs
# that might need to attach additional resources to these VPCs
# ---------------------------------------------------------------------------

output "hub_vpc_id" {
  description = "ID of the hub VPC"
  value       = aws_vpc.hub.id
}

output "spoke_vpc_id" {
  description = "ID of the spoke VPC"
  value       = aws_vpc.spoke.id
}

# ---------------------------------------------------------------------------
# Subnet IDs
# Need these in Phase 2 when launching EC2 instances —
# the instance resource needs to know which subnet to launch into
# ---------------------------------------------------------------------------

output "hub_public_subnet_id" {
  description = "ID of the hub public subnet (bastion will go here)"
  value       = aws_subnet.hub_public.id
}

output "hub_private_subnet_id" {
  description = "ID of the hub private subnet"
  value       = aws_subnet.hub_private.id
}

output "spoke_private_subnet_id" {
  description = "ID of the spoke private subnet (app server will go here)"
  value       = aws_subnet.spoke_private.id
}

# ---------------------------------------------------------------------------
# Peering Connection
# Confirms the peering connection was created and gives you its ID
# for verification in the AWS console (VPC > Peering Connections)
# ---------------------------------------------------------------------------

output "peering_connection_id" {
  description = "ID of the VPC peering connection between hub and spoke"
  value       = aws_vpc_peering_connection.hub_to_spoke.id
}

# ---------------------------------------------------------------------------
# NAT Gateway
# Useful to confirm the NAT gateway's public IP — this is the IP that
# private subnet traffic will appear to come from when reaching the internet
# ---------------------------------------------------------------------------

# output "nat_gateway_public_ip" {
#   description = "Public IP address of the NAT gateway"
#   value       = aws_eip.nat.public_ip
# }