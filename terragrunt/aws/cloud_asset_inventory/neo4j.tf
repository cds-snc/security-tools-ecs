resource "aws_ecs_cluster" "neo4j" {
  name = "neo4j"

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

resource "aws_ecs_service" "neo4j" {
  name                              = "neo4j"
  cluster                           = aws_ecs_cluster.neo4j.id
  task_definition                   = aws_ecs_task_definition.neo4j.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 600

  load_balancer {
    target_group_arn = aws_lb_target_group.neo4j.arn
    container_name   = "neo4j"
    container_port   = 7474
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.bolt.arn
    container_name   = "neo4j"
    container_port   = 7687
  }

  service_registries {
    registry_arn = aws_service_discovery_service.neo4j.arn
  }

  network_configuration {
    security_groups = [aws_security_group.cartography.id]
    subnets         = module.vpc.private_subnet_ids
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

data "template_file" "neo4j_container_definition" {
  template = file("container-definitions/neo4j.json.tmpl")

  vars = {
    AWS_LOGS_GROUP         = aws_cloudwatch_log_group.neo4j.name
    AWS_LOGS_REGION        = var.region
    AWS_LOGS_STREAM_PREFIX = "${aws_ecs_cluster.neo4j.name}-task"
    NEO4J_IMAGE            = "${var.neo4j_image}:${var.neo4j_image_tag}"
    NEO4J_AUTH             = aws_ssm_parameter.neo4j_auth.arn
  }
}

resource "aws_ecs_task_definition" "neo4j" {
  family                   = "neo4j"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 2048
  memory = 8192

  execution_role_arn = aws_iam_role.cartography_container_execution_role.arn
  task_role_arn      = aws_iam_role.cartography_task_execution_role.arn

  container_definitions = data.template_file.neo4j_container_definition.rendered

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

resource "aws_cloudwatch_log_group" "neo4j" {
  name              = "/aws/ecs/neo4j"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}
