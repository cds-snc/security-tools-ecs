module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.2//vpc"
  name   = var.product_name

  cidr            = "10.0.0.0/22"   # Reserve 1,022 IP addresses for VPC. 10.0.1.0/24 and 10.0.2.0/24 are flexible.
  public_subnets  = ["10.0.0.0/24"] # Reserve 254 IP addresses for public subnets
  private_subnets = ["10.0.3.0/24"] # Reserve 254 IP addresses for private subnets


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
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO THE LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "load_balancer" {
  #checkov:skip=CKV2_AWS_5:This security group will be attached to a lb in a future PR
  name        = "load_balancer"
  description = "Allow inbound traffic to cartography load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Access to load balancer neo4j"
    from_port   = 7474
    to_port     = 7474
    protocol    = "tcp"
    cidr_blocks = module.vpc.public_subnet_cidr_blocks
  }

  ingress {
    description = "Access to load balancer neo4j bolt"
    from_port   = 7687
    to_port     = 7687
    protocol    = "tcp"
    cidr_blocks = module.vpc.public_subnet_cidr_blocks
  }

  ingress {
    description = "Access to load balancer from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = module.vpc.public_subnet_cidr_blocks
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO CARTOGRAPHY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "cartography" {
  #checkov:skip=CKV2_AWS_5:This security group will be attached to a lb in a future PR
  name        = "cartography"
  description = "Allow inbound traffic to cartography load balancer"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Access to efs"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
  }

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
    description = "Access from the load balancer"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = module.vpc.public_subnet_cidr_blocks
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
    cidr_blocks = module.vpc.public_subnet_cidr_blocks
    self        = true
  }

  ingress {
    description = "Access to neo4j https"
    from_port   = 7473
    to_port     = 7473
    protocol    = "tcp"
    cidr_blocks = module.vpc.public_subnet_cidr_blocks
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
    cidr_blocks = module.vpc.public_subnet_cidr_blocks
    self        = true
  }
}

resource "aws_flow_log" "cartography" {
  iam_role_arn    = aws_iam_role.cartography_task_execution_role.arn
  log_destination = aws_cloudwatch_log_group.cartography_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "cartography_flow_log" {
  name              = "cartography_flow_log"
  retention_in_days = 14
}
