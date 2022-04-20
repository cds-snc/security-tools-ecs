variable "session_key" {
  description = "The pomerium auth session key"
  type        = string
  sensitive   = true
}

variable "session_cookie_secret" {
  description = "The pomerium seed string for secure cookies"
  type        = string
  sensitive   = true
}

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
