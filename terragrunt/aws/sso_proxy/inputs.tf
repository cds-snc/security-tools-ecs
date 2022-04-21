variable "pomerium_client_id" {
  description = "The pomerium client id"
  type        = string
  sensitive   = true
}

variable "pomerium_client_secret" {
  description = "The pomerium client secret"
  type        = string
  sensitive   = true
}

variable "pomerium_image" {
  description = "The pomerium image to use"
  type        = string
}

variable "pomerium_image_tag" {
  description = "The pomerium image tag to use"
  type        = string
}

variable "pomerium_google_client_id" {
  description = "The pomerium google sso client id"
  type        = string
  sensitive   = true
}

variable "pomerium_google_client_secret" {
  description = "The pomerium google sso client secret"
  type        = string
  sensitive   = true
}

variable "pomerium_verify_image" {
  description = "The pomerium verify image to use for the sso proxy"
  type        = string
}

variable "pomerium_verify_image_tag" {
  description = "The pomerium verify image tag to use"
  type        = string
}

variable "session_cookie_secret" {
  description = "The pomerium seed string for secure cookies"
  type        = string
  sensitive   = true
}

variable "session_key" {
  description = "The pomerium auth session key"
  type        = string
  sensitive   = true
}
