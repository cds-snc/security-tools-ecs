# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
variable "account_id" {
  description = "Source account id"
  type        = string
}

variable "cbs_satellite_bucket_name" {
  description = "(Required) Name of the Cloud Based Sensor S3 satellite bucket"
  type        = string
}

variable "domain_name" {
  description = "(Required) Domain name to deploy to"
  type        = string
}

variable "internal_domain_name" {
  description = "(Required) Internal domain name for service discovery"
  type        = string
}

variable "product_name" {
  description = "(Required) The name of the product you are deploying."
  type        = string
}

variable "region" {
  description = "Resource region"
  type        = string
  default     = "ca-central-1"
}

variable "billing_tag_key" {
  description = "The default tagging key"
  type        = string
}

variable "billing_tag_value" {
  description = "The default tagging value"
  type        = string
}
