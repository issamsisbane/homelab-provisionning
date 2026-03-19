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
