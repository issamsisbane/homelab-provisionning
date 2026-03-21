terraform {
 	backend "pg" {
    conn_str      = var.statefile_postgresql_uri
    schema_name   = "openbao"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

provider "vault" {
  address = var.openbao_address
  token   = var.openbao_token
}

# -------------------------------------------------------
# Auth Kubernetes
# -------------------------------------------------------

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "config" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default.svc.cluster.local:443"
}

# -------------------------------------------------------
# KV v2 per namespace
# -------------------------------------------------------

resource "vault_mount" "kv" {
  for_each    = var.namespaces
  path        = each.key
  type        = "kv"
  description = "KV store pour ${each.key}"
  options     = { version = "2" }
}

# -------------------------------------------------------
# KV shared
# -------------------------------------------------------

resource "vault_mount" "shared" {
  path        = "shared"
  type        = "kv"
  description = "Secrets partagés entre namespaces"
  options     = { version = "2" }
}

# -------------------------------------------------------
# policy per namespace
# -------------------------------------------------------

resource "vault_policy" "namespace" {
  for_each = var.namespaces

  name = "policy-${each.key}"

  policy = <<-EOT
    path "${each.key}/data/*" {
      capabilities = ["read", "list"]
    }
    path "${each.key}/metadata/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

# -------------------------------------------------------
# Policy shared KV
# -------------------------------------------------------

resource "vault_policy" "shared_access" {
  for_each = var.namespaces_with_shared_access

  name = "policy-shared-${each.key}"

  policy = <<-EOT
    path "shared/data/*" {
      capabilities = ["read", "list"]
    }
    path "shared/metadata/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

# -------------------------------------------------------
# Kubernetes role per namespace
# -------------------------------------------------------

resource "vault_kubernetes_auth_backend_role" "namespace" {
  for_each = var.namespaces

  backend   = vault_auth_backend.kubernetes.path
  role_name = "role-${each.key}"

  bound_service_account_names      = ["sa-vault-${each.key}"]
  bound_service_account_namespaces = [each.key]

  token_policies = concat(
    [vault_policy.namespace[each.key].name],
    contains(var.namespaces_with_shared_access, each.key)
      ? [vault_policy.shared_access[each.key].name]
      : []
  )

  token_ttl     = 3600
  token_max_ttl = 7200
}
