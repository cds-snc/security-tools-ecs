resource "aws_ecs_cluster" "cloud_asset_discovery" {
  name = "cloud_asset_discovery"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}
