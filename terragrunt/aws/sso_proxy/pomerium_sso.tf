locals {
  routes_file = "configs/routes.yml"
}

resource "aws_ecs_cluster" "pomerium_sso_proxy" {
  name = "pomerium_sso_proxy"

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

resource "aws_ecs_service" "pomerium_sso_proxy" {
  name                              = "pomerium_sso_proxy"
  cluster                           = aws_ecs_cluster.pomerium_sso_proxy.id
  task_definition                   = aws_ecs_task_definition.pomerium_sso_proxy.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 600

  load_balancer {
    target_group_arn = aws_lb_target_group.sso_proxy.arn
    container_name   = "pomerium_sso_proxy"
    container_port   = 443
  }

  network_configuration {
    security_groups = [aws_security_group.pomerium.id]
    subnets         = module.vpc.private_subnet_ids
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

data "template_file" "pomerium_sso_proxy_container_definition" {
  template = file("container-definitions/pomerium_sso_proxy.json.tmpl")

  vars = {
    AUTHENTICATE_SERVICE_URL      = "https://auth.${var.domain_name}"
    AWS_LOGS_GROUP                = aws_cloudwatch_log_group.pomerium_sso_proxy.name
    AWS_LOGS_REGION               = var.region
    AWS_LOGS_STREAM_PREFIX        = "${aws_ecs_cluster.pomerium_sso_proxy.name}-task"
    COOKIE_EXPIRE                 = var.session_cookie_expires_in
    ROUTES_FILE                   = base64encode(file(local.routes_file))
    POMERIUM_CLIENT_ID            = aws_ssm_parameter.pomerium_client_id.arn
    POMERIUM_CLIENT_SECRET        = aws_ssm_parameter.pomerium_client_secret.arn
    POMERIUM_GOOGLE_CLIENT_ID     = aws_ssm_parameter.pomerium_google_client_id.arn
    POMERIUM_GOOGLE_CLIENT_SECRET = aws_ssm_parameter.pomerium_google_client_secret.arn
    POMERIUM_IMAGE                = "${var.pomerium_image}:${var.pomerium_image_tag}"
  }
}

resource "aws_ecs_task_definition" "pomerium_sso_proxy" {
  family                   = "pomerium_sso_proxy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 2048
  memory = 4096

  execution_role_arn = aws_iam_role.pomerium_container_execution_role.arn
  task_role_arn      = aws_iam_role.pomerium_task_execution_role.arn

  container_definitions = data.template_file.pomerium_sso_proxy_container_definition.rendered

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

resource "aws_cloudwatch_log_group" "pomerium_sso_proxy" {
  name              = "/aws/ecs/pomerium_sso_proxy"
  retention_in_days = 14

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}
