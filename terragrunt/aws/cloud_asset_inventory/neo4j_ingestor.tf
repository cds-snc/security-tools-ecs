locals {
  elasticsearch_config_file   = "configs/es-index.json"
  neo4j_ingestor_service_name = "neo4j_ingestor"
}

data "template_file" "neo4j_ingestor_container_definition" {
  template = file("container-definitions/neo4j_ingestor.json.tmpl")

  vars = {
    AWS_LOGS_GROUP         = aws_cloudwatch_log_group.neo4j_ingestor.name
    AWS_LOGS_REGION        = var.region
    AWS_LOGS_STREAM_PREFIX = "${local.neo4j_ingestor_service_name}-task"
    ELASTIC_URL            = "${aws_elasticsearch_domain.cartography.endpoint}:443"
    ENTRYPOINT_COMMAND = join(" ", [
      "set -ueo pipefail; echo ${base64encode(file(local.elasticsearch_config_file))} | base64 -d > /opt/es-index/es-index.json;",
      "python3 /app/elastic_ingestor.py;",
    ])
    ELASTICSEARCH_USER     = aws_ssm_parameter.elasticsearch_user.arn
    ELASTICSEARCH_PASSWORD = aws_ssm_parameter.elasticsearch_password.arn
    MIN_ECS_CAPACITY       = var.min_ecs_capacity
    MAX_ECS_CAPACITY       = var.max_ecs_capacity
    NEO4J_INGESTOR_IMAGE   = "${var.neo4j_ingestor_repository_url}:latest"
    NEO4J_SECRETS_PASSWORD = aws_ssm_parameter.neo4j_password.arn
  }
}

resource "aws_ecs_task_definition" "neo4j_ingestor" {
  family                   = local.neo4j_ingestor_service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 2048
  memory = 4096

  execution_role_arn = aws_iam_role.cartography_container_execution_role.arn
  task_role_arn      = aws_iam_role.cartography_task_execution_role.arn

  container_definitions = data.template_file.neo4j_ingestor_container_definition.rendered

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }

  volume {
    name = "elasticsearch-index-volume"
  }
}

resource "aws_cloudwatch_log_group" "neo4j_ingestor" {
  name              = "/aws/ecs/${local.neo4j_ingestor_service_name}"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}
