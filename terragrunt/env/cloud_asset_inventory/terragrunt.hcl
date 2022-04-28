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
  neo4j_image                      = "neo4j"
  neo4j_image_tag                  = "4.4@sha256:aabe1e6e19a8582d7fd9a42f7317b0e260e7870ce3e6b4dacffb2f7d6d141a31"
}

include {
  path   = find_in_parent_folders()
  expose = true
}