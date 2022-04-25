variable "asset_inventory_managed_accounts" {
  description = "(Optional) List of AWS accounts to manage cloud asset inventory for."
  type        = list(string)
  default     = []
}

variable "password_change_id" {
  description = "(Required) Id to trigger changing the elasticsearch and neo4j password."
  type        = string
  default     = "1970-01-01"
}

variable "ssm_prefix" {
  description = "(Required) Prefix to apply to all key names"
  type        = string
  default     = "cartography"
}
