output "kv_mounts" {
  description = "KV mounts created"
  value       = { for k, v in vault_mount.kv : k => v.path }
}

output "policies_created" {
  description = "Policies created"
  value       = { for k, v in vault_policy.namespace : k => v.name }
}

output "roles_created" {
  description = "Kubernetes roles created"
  value       = { for k, v in vault_kubernetes_auth_backend_role.namespace : k => v.role_name }
}
