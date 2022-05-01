module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.2//vpc"
  name   = var.product_name

  cidr            = var.cloud_asset_inventory_cidr # Reserve 1,022 IP addresses for VPC. 10.0.9.0/24 and 10.0.10.0/24 are flexible.
  public_subnets  = ["10.0.8.0/24"]                # Reserve 254 IP addresses for public subnets
  private_subnets = ["10.0.11.0/24"]               # Reserve 254 IP addresses for private subnets


  high_availability = false
  enable_flow_log   = false
  block_ssh         = true
  block_rdp         = true
  enable_eip        = true

  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true

  billing_tag_key   = "CostCentre"
  billing_tag_value = var.billing_tag_value
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO CARTOGRAPHY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "cartography" {
  #checkov:skip=CKV2_AWS_5:This security group will be attached to a lb in a future PR
  name        = "cartography"
  description = "Allow inbound traffic to cartography load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Access to efs"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
  }

  egress {
    description = "Outbound access to internet & elasticsearch"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access to services running on https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.sso_proxy_cidr]
  }

  egress {
    description = "Outbound access to neo4j http"
    from_port   = 7474
    to_port     = 7474
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
    self        = true
  }

  ingress {
    description = "Inbound access to neo4j http"
    from_port   = 7474
    to_port     = 7474
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
    self        = true
  }

  ingress {
    description = "Access to neo4j https"
    from_port   = 7473
    to_port     = 7473
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
    self        = true
  }

  egress {
    description = "Outbound access to neo4j bolt"
    from_port   = 7687
    to_port     = 7687
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
    self        = true
  }

  ingress {
    description = "Inbound access to neo4j bolt"
    from_port   = 7687
    to_port     = 7687
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
    self        = true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

resource "aws_flow_log" "cloud-based-sensor" {
  log_destination      = "arn:aws:s3:::${var.cbs_satellite_bucket_name}/vpc_flow_logs/"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id
  log_format           = "$${vpc-id} $${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${subnet-id} $${instance-id}"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}
