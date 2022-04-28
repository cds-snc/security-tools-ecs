resource "aws_vpc_peering_connection" "cloud_asset_inventory" {
  vpc_id        = module.vpc.vpc_id
  peer_vpc_id   = var.cloud_asset_inventory_vpc_id
  peer_owner_id = var.account_id
  peer_region   = var.region
  auto_accept   = false

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Side = "Requester"
  }
}

resource "aws_route" "cloud_asset_inventory" {
  count                     = length(module.vpc.private_route_table_ids)
  route_table_id            = element(module.vpc.private_route_table_ids, count.index)
  destination_cidr_block    = var.cloud_asset_inventory_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.cloud_asset_inventory.id
}
