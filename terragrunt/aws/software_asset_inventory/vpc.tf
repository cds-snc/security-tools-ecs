module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.2//vpc"
  name   = var.product_name

  cidr            = var.software_asset_inventory_cidr # Reserve 254 IP addresses for VPC
  public_subnets  = ["10.0.12.0/26"]                  # Reserve 62 IP addresses for public subnets
  private_subnets = ["10.0.12.128/26"]                # Reserve 62 IP addresses for private subnets

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
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO DEPENDENCY TRACK
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "dependencytrack" {
  name        = "dependencytrack"
  description = "Allow inbound traffic to dependencytrack load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow NFS traffic out from ECS to mount target"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
  }

  egress {
    description = "Allow NFS traffic into mount target from ECS"
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
    cidr_blocks = concat(module.vpc.private_subnet_cidr_blocks, [var.sso_proxy_cidr])
  }

  egress {
    description = "Outbound access to dependency track api"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
    self        = true
  }

  ingress {
    description = "Inbound access to dependency track api"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = concat(module.vpc.private_subnet_cidr_blocks, [var.sso_proxy_cidr])
    self        = true
  }

  egress {
    description = "Outbound access to dependency track frontend"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
    self        = true
  }

  ingress {
    description = "Access to dependency track frontend"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = concat(module.vpc.private_subnet_cidr_blocks, [var.sso_proxy_cidr])
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
