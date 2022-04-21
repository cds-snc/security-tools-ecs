inputs = {
  account_id                = "${get_aws_account_id()}"
  domain_name               = "security.cdssandbox.xyz"
  internal_domain_name      = "${get_aws_account_id()}.local"
  product_name              = "security-tools"
  billing_tag_key           = "CostCentre"
  billing_tag_value         = "security-tools-${get_aws_account_id()}"
  region                    = "ca-central-1"
  cbs_satellite_bucket_name = "cbs-satellite-${local.vars.inputs.account_id}"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    encrypt        = true
    bucket         = "security-tools-${get_aws_account_id()}-tfstate"
    dynamodb_table = "tfstate-lock"
    region         = "ca-central-1"
    key            = "${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = file("./common/provider.tf")
}

generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite"
  contents  = file("./common/common_variables.tf")
}
