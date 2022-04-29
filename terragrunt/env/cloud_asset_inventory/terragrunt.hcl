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
  product_name                                    = "security-tools-cloud-asset-inventory"
  asset_inventory_managed_accounts                = split("\n", chomp(replace(file("configs/accounts.txt"), "\"", "")))
  cartography_repository_url                      = dependency.base.outputs.cartography_repository_url
  neo4j_image                                     = "neo4j"
  neo4j_image_tag                                 = "3.5.32@sha256:a5e2dc0ee57c7943342c981b5037c1bf961980f00fe8d6f6304d2b24102d6f5b"
  neo4j_ingestor_repository_url                   = dependency.base.outputs.neo4j_ingestor_repository_url
  cloud_asset_inventory_vpc_peering_connection_id = "pcx-0771c54d393000439"
}

include {
  path   = find_in_parent_folders()
  expose = true
}