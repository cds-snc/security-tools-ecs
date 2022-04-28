terraform {
  source = "../../aws//sso_proxy"
}

dependencies {
  paths = ["../cloud_asset_inventory"]
}

dependency "cloud_asset_inventory" {
  config_path = "../cloud_asset_inventory"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    cloud_asset_inventory_vpc_id            = "vpc-1234567890abcdef0"
    cloud_asset_inventory_load_balancer_dns = "my-loadbalancer-1234567890.us-west-2.elb.amazonaws.com"
  }
}

inputs = {
  product_name                            = "security-tools-sso-proxy"
  pomerium_image                          = "pomerium/pomerium"
  pomerium_image_tag                      = "git-74310b3d"
  pomerium_verify_image                   = "pomerium/verify"
  pomerium_verify_image_tag               = "sha-6b38dd5"
  session_cookie_expires_in               = "8h"
  cloud_asset_inventory_vpc_id            = dependency.cloud_asset_inventory.outputs.cloud_asset_inventory_vpc_id
  cloud_asset_inventory_load_balancer_dns = dependency.cloud_asset_inventory.outputs.cloud_asset_inventory_load_balancer_dns
}

include {
  path   = find_in_parent_folders()
  expose = true
}