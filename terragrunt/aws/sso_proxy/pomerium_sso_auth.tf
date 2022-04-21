resource "aws_ecs_cluster" "pomerium_sso_proxy_auth" {
  name = "pomerium_sso_proxy_auth"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "pomerium_sso_proxy_auth" {
  name            = "pomerium_sso_proxy_auth"
  cluster         = aws_ecs_cluster.pomerium_sso_proxy_auth.id
  task_definition = aws_ecs_task_definition.pomerium_sso_proxy_auth.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  service_registries {
    registry_arn = aws_service_discovery_service.auth.arn
  }

  network_configuration {
    security_groups = [aws_security_group.pomerium.id]
    subnets         = module.vpc.private_subnet_ids
  }
}

resource "aws_ecs_task_definition" "pomerium_sso_proxy_auth" {
  family                   = "pomerium_sso_proxy_auth"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = 1024
  memory = 2048

  execution_role_arn = aws_iam_role.pomerium_container_execution_role.arn
  task_role_arn      = aws_iam_role.pomerium_task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name" : "pomerium_sso_proxy_auth",
      "cpu" : 0,
      "environment" : [
        {
          "name" : "IDP_PROVIDER",
          "value" : "google"
        },
        {
          "name" : "LOG_LEVEL",
          "value" : "debug"
        },
      ],
      "essential" : true,
      "image" : "pomerium/verify:sha-6b38dd5",
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.pomerium_sso_proxy_auth.name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "ecs-pomerium_auth"
        }
      },
      "portMappings" : [
        {
          "hostPort" : 8000,
          "ContainerPort" : 8000,
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
}

resource "aws_cloudwatch_log_group" "pomerium_sso_proxy_auth" {
  name              = "/aws/ecs/pomerium_sso_proxy_auth"
  retention_in_days = 14
}
