###
# The task execution role grants the Amazon ECS container and Fargate agents 
# permission to make AWS API calls on your behalf
###

resource "aws_iam_role" "pomerium_task_execution_role" {
  name               = "pomerium_execution_role"
  assume_role_policy = data.aws_iam_policy_document.pomerium_task_execution_role.json
}

data "aws_iam_policy_document" "pomerium_task_execution_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.pomerium_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policies" {
  role       = aws_iam_role.pomerium_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registery_policies" {
  role       = aws_iam_role.pomerium_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecs_container_registery_policies" {
  role       = aws_iam_role.pomerium_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_role_policy_attachment" "pomerium_policies" {
  role       = aws_iam_role.pomerium_task_execution_role.name
  policy_arn = aws_iam_policy.pomerium_policies.arn
}

data "aws_iam_policy_document" "pomerium_policies" {
  statement {

    effect = "Allow"

    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.pomerium_google_client_id.arn,
      aws_ssm_parameter.pomerium_google_client_secret.arn,
      aws_ssm_parameter.session_key.arn,
      aws_ssm_parameter.session_cookie_secret.arn,
      aws_ssm_parameter.pomerium_client_id.arn,
      aws_ssm_parameter.pomerium_client_secret.arn,
    ]
  }
}

resource "aws_iam_policy" "pomerium_policies" {
  name   = "PomeriumSSOTaskExecutionPolicies"
  path   = "/"
  policy = data.aws_iam_policy_document.pomerium_policies.json
}
