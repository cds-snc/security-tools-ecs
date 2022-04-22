output "sso_proxy_vpc_id" {
  description = "The VPC ID for the SSO Proxy"
  value       = module.vpc.vpc_id
}
output "internal_hosted_zone_id" {
  description = "The internal hosted zone id"
  value       = aws_service_discovery_private_dns_namespace.internal.hosted_zone
}
