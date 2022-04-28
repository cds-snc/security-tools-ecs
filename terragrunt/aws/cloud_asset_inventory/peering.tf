resource "aws_vpc_peering_connection_accepter" "sso_proxy" {
  vpc_peering_connection_id = var.cloud_asset_inventory_vpc_peering_connection_id
  auto_accept               = true

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
    Side                  = "Accepter"
  }
}

resource "aws_vpc_peering_connection_options" "sso_proxy" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.sso_proxy.id

  accepter {
    allow_remote_vpc_dns_resolution  = true
    allow_classic_link_to_remote_vpc = false
    allow_vpc_to_remote_classic_link = false
  }
}

resource "aws_route" "account_1" {
  count                     = length(module.vpc.private_route_table_ids)
  route_table_id            = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block    = var.sso_proxy_cidr
  vpc_peering_connection_id = var.cloud_asset_inventory_vpc_peering_connection_id
}
