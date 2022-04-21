locals {
  policy_file = "configs/policy.yml"
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
    target_group_arn = aws_lb_target_group.ecs.arn
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

resource "aws_ecs_task_definition" "pomerium_sso_proxy" {
  family                   = "pomerium_sso_proxy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 2048
  memory = 4096

  execution_role_arn = aws_iam_role.pomerium_container_execution_role.arn
  task_role_arn      = aws_iam_role.pomerium_task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "pomerium_sso_proxy",
      "cpu" : 0,
      "environment" : [
        {
          "name" : "POLICY",
          "value" : base64encode(file(local.policy_file))
        },
        {
          "name" : "IDP_PROVIDER",
          "value" : "google"
        },
        {
          "name" : "AUTHENTICATE_SERVICE_URL",
          "value" : "https://auth.${var.domain_name}"
        },
        {
          "name" : "AUTOCERT",
          "value" : "FALSE"
        },
        {
          "name" : "INSECURE_SERVER",
          "value" : "true"
        },
        {
          "name" : "LOG_LEVEL",
          "value" : "debug"
        },
      ],
      "essential" : true,
      "image" : "pomerium/pomerium:git-74310b3d",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.pomerium_sso_proxy.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-pomerium"
        }
      },
      "portMappings" : [
        {
          "hostPort" : 443,
          "ContainerPort" : 443,
          "Protocol" : "tcp"
        }
      ],
      "secrets" : [
        {
          "name" : "SHARED_SECRET",
          "valueFrom" : aws_ssm_parameter.pomerium_client_id.arn
        },
        {
          "name" : "COOKIE_SECRET",
          "valueFrom" : aws_ssm_parameter.pomerium_client_secret.arn
        },
        {
          "name" : "IDP_CLIENT_ID",
          "valueFrom" : aws_ssm_parameter.pomerium_google_client_id.arn
        },
        {
          "name" : "IDP_CLIENT_SECRET",
          "valueFrom" : aws_ssm_parameter.pomerium_google_client_secret.arn
        },
      ],
    },
  ])

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
