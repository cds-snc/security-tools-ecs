resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = var.internal_domain_name
  description = "internal domain for all services"
  vpc         = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "auth" {
  name = "auth"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 5
  }
}
