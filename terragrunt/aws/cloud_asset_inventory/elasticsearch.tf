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
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = aws_ssm_parameter.elasticsearch_user.value
      master_user_password = aws_ssm_parameter.elasticsearch_password.value
    }
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

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.elasticsearch.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }

  depends_on = [
    aws_cloudwatch_log_resource_policy.elasticsearch,
  ]
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
  description      = "Allows Amazon ES to manage AWS resources for a domain on your behalf."

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
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

resource "aws_cloudwatch_log_resource_policy" "elasticsearch" {
  policy_name     = "CloudWatchElasticSearchLogPolicy"
  policy_document = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": [
        "logs:PutLogEvents",
        "logs:PutLogEventsBatch",
        "logs:CreateLogStream"
      ],
      "Resource": ["${aws_cloudwatch_log_group.elasticsearch.arn}", "${aws_cloudwatch_log_group.elasticsearch.arn}:log-group:${aws_cloudwatch_log_group.elasticsearch.name}:log-stream:*"]
    }
  ]
}
CONFIG
}

resource "aws_cloudwatch_log_group" "elasticsearch" {
  name              = "/aws/ecs/elasticsearch"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}
