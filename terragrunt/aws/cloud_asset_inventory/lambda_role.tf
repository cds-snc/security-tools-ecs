#
# IAM
#

resource "aws_iam_role" "cartography_launcher_lambda" {
  name               = "Lambda"
  assume_role_policy = data.aws_iam_policy_document.cartography_launcher_lambda_assume.json

  tags = {
    CostCentre = "Platform"
    Terraform  = true
  }
}

resource "aws_iam_policy" "cartography_launcher_lambda" {
  name   = "CartographyLauncherLambdaRolePolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.cartography_launcher_lambda.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

resource "aws_iam_role_policy_attachment" "cartography_launcher_lambda_basic_execution" {
  role       = aws_iam_role.cartography_launcher_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cartography_launcher_lambda_xray_write" {
  role       = aws_iam_role.cartography_launcher_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "cartography_launcher_lambda" {
  role       = aws_iam_role.cartography_launcher_lambda.name
  policy_arn = aws_iam_policy.cartography_launcher_lambda.arn
}

data "aws_iam_policy_document" "cartography_launcher_lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cartography_launcher_lambda" {
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
      "ecs:RunTask",
    ]
    resources = [
      aws_ecs_task_definition.cartography.arn,
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
