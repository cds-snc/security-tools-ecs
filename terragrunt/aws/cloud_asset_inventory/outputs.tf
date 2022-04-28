output "cloud_asset_inventory_vpc_id" {
  description = "The VPC ID for Cloud Asset Inventory"
  value       = module.vpc.vpc_id
}

output "cloud_asset_inventory_load_balancer_dns" {
  description = "The DNS name of the Cloud Asset Inventory load balancer"
  value       = aws_lb.cartography.dns_name
}
