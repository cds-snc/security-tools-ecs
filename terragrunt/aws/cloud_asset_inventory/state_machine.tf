resource "aws_cloudwatch_event_rule" "asset_inventory_cartography" {
  name                = "cartography"
  schedule_expression = "cron(0 22 * * ? *)"
  is_enabled          = false
}

resource "aws_cloudwatch_event_target" "sfn_events" {
  rule     = aws_cloudwatch_event_rule.asset_inventory_cartography.name
  arn      = aws_sfn_state_machine.asset_inventory_cartography.arn
  role_arn = aws_iam_role.asset_inventory_cartography_state_machine.arn
}

data "template_file" "asset_inventory_cartography_state_machine" {
  template = file("state-machines/cartography.json.tmpl")

  vars = {
    CARTOGRAPHY_CLUSTER       = aws_ecs_cluster.cartography.name
    NEO4J_INGESTOR_CLUSTER    = aws_ecs_cluster.neo4j_ingestor.name
    NEO4J_INGESTOR_TASK_DEF   = aws_ecs_task_definition.neo4j_ingestor.family
    LAUNCH_CARTOGRAPHY_LAMBDA = "${aws_lambda_function.cartography_launcher.arn}:$LATEST"
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
      aws_ecs_task_definition.neo4j_ingestor.arn
    ]
  }

  statement {

    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      "${aws_lambda_function.cartography_launcher.arn}:*"
    ]
  }

}
