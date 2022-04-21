module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.2//vpc"
  name   = var.product_name

  cidr            = "172.16.0.0/16"
  public_subnets  = ["172.16.0.0/20", "172.16.16.0/20", "172.16.32.0/20"]
  private_subnets = ["172.16.128.0/20", "172.16.144.0/20", "172.16.160.0/20"]


  high_availability = true
  enable_flow_log   = false
  block_ssh         = true
  block_rdp         = true
  enable_eip        = true

  billing_tag_key   = "CostCentre"
  billing_tag_value = var.billing_tag_value
}

resource "aws_network_acl_rule" "https" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ephemeral_ports" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 111
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "https_egress" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ephemeral_ports_egress" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 111
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}
# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO BUZZFEED SSO
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "pomerium" {
  name        = "pomerium"
  description = "Allow inbound traffic to pomerium load balancer"
  vpc_id      = module.vpc.vpc_id


  ingress {
    description = "Access to load balancer"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access from proxy"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow API outbound connections to the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow API outbound connections to the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow API outbound connections to the proxy"
    from_port   = 8000
    to_port     = 8000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

resource "aws_flow_log" "pomerium" {
  iam_role_arn    = aws_iam_role.pomerium_task_execution_role.arn
  log_destination = aws_cloudwatch_log_group.pomerium_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

resource "aws_cloudwatch_log_group" "pomerium_flow_log" {
  name              = "pomerium_flow_log"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}
