variable "asset_inventory_managed_accounts" {
  description = "(Optional) List of AWS accounts to manage cloud asset inventory for."
  type        = list(string)
  default     = []
}

variable "password_change_id" {
  description = "(Required) Id to trigger changing the elasticsearch and neo4j password."
  type        = string
}

variable "ssm_prefix" {
  description = "(Required) Prefix to apply to all key names"
  type        = string
  default     = "cartography"
}

variable "cartography_repository_url" {
  description = "(Required) URL to the cartography repository"
  type        = string
}
