module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.2//vpc"
  name   = var.product_name

  cidr            = "172.16.0.0/25"
  public_subnets  = ["172.16.0.0/28", "172.16.0.16/28", "172.16.0.32/28"]
  private_subnets = ["172.16.0.64/28", "172.16.0.80/28", "172.16.0.96/28"]


  high_availability = true
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
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO POMERIUM SSO
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "pomerium" {
  name        = "pomerium"
  description = "Allow inbound traffic to pomerium load balancer"
  vpc_id      = module.vpc.vpc_id


  egress {
    description = "Access to the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access to load balancer from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access from proxy to pomerium auth"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow API outbound connections to the proxy"
    from_port   = 8000
    to_port     = 8000
    protocol    = "TCP"
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
