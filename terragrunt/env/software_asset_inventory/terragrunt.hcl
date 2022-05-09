terraform {
  source = "../../aws//software_asset_inventory"
}

inputs = {
  product_name                       = "security-tools-software-asset-inventory"
  dependencytrack_api_image          = "dependencytrack/apiserver"
  dependencytrack_api_image_tag      = "4.4.2@sha256:584cfd2349ec93cfde2528b8f34bd5d3a9f0a393fa38806128d646743fa649ee"
  dependencytrack_frontend_image     = "dependencytrack/frontend"
  dependencytrack_frontend_image_tag = "4.4.0@sha256:e0b6790c19cba4470468a5cbd8eaaf80c8b9cd4c3c9be5b993032fbec5ed0daa"
}

include {
  path   = find_in_parent_folders()
  expose = true
}