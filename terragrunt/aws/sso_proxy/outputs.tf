output "cloud_asset_inventory_vpc_peering_connection_id" {
  description = "The VPC peering connection ID for Cloud Asset Inventory"
  value       = aws_vpc_peering_connection.cloud_asset_inventory.id
}

output "sso_proxy_vpc_id" {
  description = "The VPC ID for the SSO Proxy"
  value       = module.vpc.vpc_id
}

output "internal_hosted_zone_id" {
  description = "The internal hosted zone id"
  value       = aws_service_discovery_private_dns_namespace.internal.hosted_zone
}
