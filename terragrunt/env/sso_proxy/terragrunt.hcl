terraform {
  source = "../../aws//sso_proxy"
}

inputs = {
  product_name              = "security-tools-sso-proxy"
  pomerium_image            = "pomerium/pomerium"
  pomerium_image_tag        = "git-74310b3d"
  pomerium_verify_image     = "pomerium/verify"
  pomerium_verify_image_tag = "sha-6b38dd5"
  session_cookie_expires_in = "8h"
}

include {
  path   = find_in_parent_folders()
  expose = true
}