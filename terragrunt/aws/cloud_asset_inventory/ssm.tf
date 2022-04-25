# All passwords in this file are set to rotate automatically every month.
# Inspired by https://www.daringway.com/how-to-rotate-random-passwords-in-terraform/
resource "random_password" "elasticsearch_password" {
  for_each = toset([var.password_change_id])
  length   = 32
  special  = false
}

resource "random_password" "neo4j_password" {
  for_each = toset([var.password_change_id])
  length   = 32
  special  = false
}

resource "random_string" "elasticsearch_user" {
  length  = 10
  special = false
}

resource "aws_ssm_parameter" "neo4j_password" {
  name  = "/${var.ssm_prefix}/neo4j_password"
  type  = "SecureString"
  value = random_password.neo4j_password[var.password_change_id].result
}

resource "aws_ssm_parameter" "neo4j_auth" {
  name  = "/${var.ssm_prefix}/neo4j_auth"
  type  = "SecureString"
  value = "neo4j/${random_password.neo4j_password[var.password_change_id].result}"
}

resource "aws_ssm_parameter" "elasticsearch_user" {
  name  = "/${var.ssm_prefix}/elasticsearch_user"
  type  = "String"
  value = random_string.elasticsearch_user.id
}

resource "aws_ssm_parameter" "elasticsearch_password" {
  name  = "/${var.ssm_prefix}/elasticsearch_password"
  type  = "SecureString"
  value = random_password.elasticsearch_password[var.password_change_id].result
}

resource "aws_ssm_parameter" "asset_inventory_account_list" {
  name  = "/${var.ssm_prefix}/asset_inventory_account_list"
  type  = "StringList"
  value = jsonencode(var.asset_inventory_managed_accounts)
}

