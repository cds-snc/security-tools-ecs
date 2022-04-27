resource "aws_ecs_cluster" "cartography" {
  name = "cartography"

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

data "template_file" "cartography_container_definition" {
  template = file("container-definitions/cartography.json.tmpl")

  vars = {
    AWS_LOGS_GROUP         = aws_cloudwatch_log_group.cartography.name
    AWS_LOGS_REGION        = var.region
    AWS_LOGS_STREAM_PREFIX = "${aws_ecs_cluster.cartography.name}-task"
    CARTOGRAPHY_IMAGE      = "${var.cartography_repository_url}:latest"
    NEO4J_SECRETS_PASSWORD = aws_ssm_parameter.neo4j_password.arn
  }
}

resource "aws_ecs_task_definition" "cartography" {
  family                   = "cartography"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 4096
  memory = 16384

  execution_role_arn = aws_iam_role.cartography_container_execution_role.arn
  task_role_arn      = aws_iam_role.cartography_task_execution_role.arn

  container_definitions = data.template_file.cartography_container_definition.rendered

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

resource "aws_cloudwatch_log_group" "cartography" {
  name              = "/aws/ecs/cartography"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}
