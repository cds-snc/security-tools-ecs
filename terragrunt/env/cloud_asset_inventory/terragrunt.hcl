terraform {
  source = "../../aws//cloud_asset_inventory"
}

inputs = {
  product_name                     = "security-tools-cloud-asset-inventory"
  asset_inventory_managed_accounts = split("\n", chomp(replace(file("configs/accounts.txt"), "\"", "")))
}

include {
  path   = find_in_parent_folders()
  expose = true
}