variable "dependencytrack_api_image" {
  description = "(Required) The dependency track API image."
  type        = string
}

variable "dependencytrack_api_image_tag" {
  description = "(Required) The dependency track API image tag."
  type        = string
}

variable "dependencytrack_frontend_image" {
  description = "(Required) The dependency track frontend image."
  type        = string
}

variable "dependencytrack_frontend_image_tag" {
  description = "(Required) The dependency track frontend image tag."
  type        = string
}

variable "password_change_id" {
  description = "(Required) Id to trigger changing the rds password."
  type        = string
}

variable "ssm_prefix" {
  description = "(Required) Prefix to apply to all key names"
  type        = string
  default     = "dependencytrack"
}
