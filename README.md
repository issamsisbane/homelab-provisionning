# homelab-provisionning

Infrastructure-as-code for a 3-node homelab Kubernetes cluster. The repository covers the full lifecycle from bare-metal OS installation to running workloads with secret management.

> GitOps configuration lives in [homelab-gitops](https://github.com/issamsisbane/homelab-gitops).

## Components

| Directory | Tool | Purpose |
|-----------|------|---------|
| `machines/` | cloud-init | Automated Ubuntu installation on bare-metal nodes |
| `ansible/` | Ansible + Kubespray | Kubernetes cluster deployment and node configuration |
| `terraform/openbao/` | OpenTofu + OpenBao | Secrets management for Kubernetes workloads |

## Architecture overview

```
bare-metal nodes
      │
      ▼  (cloud-init user-data)
machines/ ──► Ubuntu installed, kuadm user created, WiFi configured
      │
      ▼  (Ansible)
ansible/ ──► Kubernetes cluster (Kubespray), Tailscale VPN on all nodes
      │
      ▼  (OpenTofu)
terraform/openbao/ ──► OpenBao KV stores + policies per namespace
```

Tailscale provides the VPN mesh between nodes and exposes OpenBao via a stable MagicDNS hostname, which is what Terraform targets.

## Provisioning order

1. Boot each node from USB with `machines/user-data` to install Ubuntu.
2. Run Ansible to install Kubernetes, then Tailscale.
3. Setup Argo App-of-Apps application and run CNPG and Openbao installation using the GitOps repo [homelab-gitops](https://github.com/issamsisbane/homelab-gitops).
4. Run OpenTofu to configure OpenBao secrets isolation per workload namespace.

## Design decisions

**Single repository for all provisioning layers** — keeping cloud-init, Ansible, and Terraform together makes the dependency chain explicit and avoids context switching across multiple repos.

**Tailscale as the networking layer** — nodes are on a home WiFi network without a static IP or public ingress. Tailscale provides stable MagicDNS hostnames (e.g. `openbao.tail7e39b9.ts.net`) without port-forwarding or a VPN server to maintain.

**OpenBao over HashiCorp Vault** — OpenBao is the community-maintained Open-Source fork of Vault after BSL licensing changes. It is API-compatible with the Vault provider, so existing tooling works unchanged.

**PostgreSQL remote state for Terraform** — state is stored in a CNPG (CloudNativePG) cluster running inside Kubernetes itself, co-located with the workloads it manages. This avoids a dependency on an external object store.I don't use Openbao to provision the underlying infrastructure but only the tools in the cluster.
