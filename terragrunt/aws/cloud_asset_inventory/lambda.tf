#
# Lambda: zip
#
data "archive_file" "cartography_launcher" {
  type        = "zip"
  source_file = "src/launch_cartography.py"
  output_path = "/tmp/launch_cartography.py.zip"
}

resource "aws_lambda_function" "cartography_launcher" {
  filename      = "/tmp/launch_cartography.py.zip"
  function_name = "launch_cartography"
  handler       = "lambda.handler"
  runtime       = "python3.8"
  timeout       = 10
  role          = aws_iam_role.cartography_launcher_lambda.arn

  source_code_hash = data.archive_file.cartography_launcher.output_base64sha256

  vpc_config {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [aws_security_group.cartography.id]
  }

  environment {
    variables = {
      CARTOGRAPHY_ECS_TASK_DEF        = aws_ecs_task_definition.cartography.family
      CARTOGRAPHY_ECS_NETWORKING      = join(", ", [for subnet in module.vpc.private_subnet_ids : subnet])
      CARTOGRAPHY_ECS_SECURITY_GROUPS = aws_security_group.cartography.id
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}
