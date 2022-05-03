resource "aws_cloudwatch_event_rule" "asset_inventory_cartography" {
  name                = "cartography"
  schedule_expression = "cron(0 22 * * ? *)"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "sfn_events" {
  rule     = aws_cloudwatch_event_rule.asset_inventory_cartography.name
  arn      = aws_sfn_state_machine.asset_inventory_cartography.arn
  role_arn = aws_iam_role.asset_inventory_cartography_state_machine.arn
}

data "template_file" "asset_inventory_cartography_state_machine" {
  template = file("state-machines/cartography.json.tmpl")

  vars = {
    CARTOGRAPHY_CONTAINER_NAME = aws_ecs_task_definition.cartography.family
    CARTOGRAPHY_CLUSTER        = aws_ecs_cluster.cloud_asset_discovery.arn
    CARTOGRAPHY_TASK_DEF       = aws_ecs_task_definition.cartography.arn
    MIN_ECS_CAPACITY           = var.min_ecs_capacity
    MAX_ECS_CAPACITY           = var.max_ecs_capacity
    NEO4J_INGESTOR_CLUSTER     = aws_ecs_cluster.cloud_asset_discovery.arn
    NEO4J_INGESTOR_TASK_DEF    = aws_ecs_task_definition.neo4j_ingestor.arn
    SECURITY_GROUPS            = aws_security_group.cartography.id
    SUBNETS                    = join(", ", [for subnet in module.vpc.private_subnet_ids : subnet])
  }
}

resource "aws_sfn_state_machine" "asset_inventory_cartography" {
  name     = "asset-inventory-cartography"
  role_arn = aws_iam_role.asset_inventory_cartography_state_machine.arn

  definition = data.template_file.asset_inventory_cartography_state_machine.rendered

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

resource "aws_iam_role" "asset_inventory_cartography_state_machine" {
  name               = "secopsAssetInventoryNeo4JIngestorRole"
  assume_role_policy = data.aws_iam_policy_document.asset_inventory_cartography_state_machine_service_principal.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

data "aws_iam_policy_document" "asset_inventory_cartography_state_machine_service_principal" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "asset_inventory_cartography_state_machine" {
  name   = "CartographyStateMachineECSLambda"
  path   = "/"
  policy = data.aws_iam_policy_document.asset_inventory_cartography_state_machine.json
}

resource "aws_iam_role_policy_attachment" "asset_inventory_cartography_state_machine" {
  role       = aws_iam_role.asset_inventory_cartography_state_machine.name
  policy_arn = aws_iam_policy.asset_inventory_cartography_state_machine.arn
}

data "aws_iam_policy_document" "asset_inventory_cartography_state_machine" {
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.cartography_task_execution_role.arn,
      aws_iam_role.cartography_container_execution_role.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "states:StartExecution",
    ]
    resources = [
      aws_sfn_state_machine.asset_inventory_cartography.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:ListTasks"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:RunTask"
    ]
    resources = [
      aws_ecs_task_definition.cartography.arn,
      aws_ecs_task_definition.neo4j_ingestor.arn,
      "arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${aws_ecs_task_definition.cartography.family}",
      "arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${aws_ecs_task_definition.neo4j_ingestor.family}",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule"
    ]
    resources = [
      "arn:aws:events:${var.region}:${var.account_id}:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter",
    ]
    resources = [
      aws_ssm_parameter.asset_inventory_account_list.arn,
    ]
  }
}
