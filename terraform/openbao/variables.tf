variable "statefile_postgresql_uri" {
  type    = string
  default  = ""
}

variable "openbao_address" {
  type    = string
  default = "http://openbao.openbao.svc.cluster.local:8200"
}

variable "openbao_token" {
  type      = string
  sensitive = true
}

variable "namespaces" {
  type    = set(string)
  default = []
}

variable "namespaces_with_shared_access" {
  type    = set(string)
  default = []
}


variable "authelia_issuer_url" {
  description = "URL d'issuer/discovery Authelia"
  type        = string
  default     = "https://auth.issamhomelab.org"
}

variable "oidc_client_id" {
  type    = string
  default = "openbao"
}

variable "oidc_client_secret" {
  description = "Secret du client OIDC déclaré côté Authelia"
  type        = string
  sensitive   = true
}

variable "oidc_redirect_uris" {
  type = list(string)
  default = [
    "https://openbao.tail7e39b9.ts.net/ui/vault/auth/oidc/oidc/callback",
    "https://openbao.tail7e39b9.ts.net/v1/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]
}
