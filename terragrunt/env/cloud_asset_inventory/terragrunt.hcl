terraform {
  source = "../../aws//cloud_asset_inventory"
}

dependencies {
  paths = ["../base"]
}

dependency "base" {
  config_path = "../base"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    cartography_repository_url = "https://12345678910.dkr.ecr.region.amazonaws.com/foo"
  }
}

inputs = {
  product_name                     = "security-tools-cloud-asset-inventory"
  asset_inventory_managed_accounts = split("\n", chomp(replace(file("configs/accounts.txt"), "\"", "")))
  cartography_repository_url       = dependency.base.outputs.cartography_repository_url
}

include {
  path   = find_in_parent_folders()
  expose = true
}