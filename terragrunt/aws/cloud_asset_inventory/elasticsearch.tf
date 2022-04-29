resource "aws_elasticsearch_domain" "cartography" {
  domain_name           = "cartography"
  elasticsearch_version = "7.10"

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled = true
  }

  cluster_config {
    instance_type = "t3.medium.elasticsearch"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 25
  }

  vpc_options {
    security_group_ids = [aws_security_group.cartography.id]
    subnet_ids         = module.vpc.private_subnet_ids
  }
}

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name     = aws_elasticsearch_domain.cartography.domain_name
  access_policies = <<POLICIES
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "es:*",
              "Principal": "*",
              "Effect": "Allow",
              "Principal": {
                "AWS": "*"
              },
              "Resource": "${aws_elasticsearch_domain.cartography.arn}/*"
          }
      ]
  }
  POLICIES
}
