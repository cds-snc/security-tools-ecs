locals {
  name_prefix = var.product_name
}

module "log_bucket" {
  source            = "github.com/cds-snc/terraform-modules?ref=v0.0.47//S3_log_bucket"
  bucket_name       = "${var.product_name}-logs"
  billing_tag_value = var.billing_tag_value
}