terraform {
  source = "../../aws//sso_proxy"
}

inputs = {
  pomerium_image            = "pomerium/pomerium"
  pomerium_image_tag        = "git-74310b3d"
  pomerium_verify_image     = "pomerium/verify"
  pomerium_verify_image_tag = "sha-6b38dd5"
}

include {
  path   = find_in_parent_folders()
  expose = true
}