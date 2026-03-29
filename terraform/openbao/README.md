# Terraform — OpenBao

Configures [OpenBao](https://openbao.org/) (open-source Vault fork) to provide isolated secret stores for each Kubernetes namespace, using Kubernetes service account tokens for authentication.

## What is provisioned

For each namespace listed in `terraform.tfvars`:

- A **KV v2 mount** at `/<namespace>` — secrets storage scoped to that namespace
- A **policy** `policy-<namespace>` — read/list access restricted to that namespace's mount
- A **Kubernetes auth role** `role-<namespace>` — binds service account `sa-vault-<namespace>` in the namespace to its policy

For namespaces listed in `namespaces_with_shared_access`, an additional policy grants read/list access to the `shared/` KV mount.

A single **shared KV v2 mount** at `/shared` is always created for cross-namespace secrets.

## Prerequisites

- OpenTofu >= 1.11.5
- `task` CLI (Taskfile runner)
- `kubectl` with access to the cluster (for port-forwarding the state backend)
- `direnv` to load environment variables

## How to run

### 1. Configure environment

Copy `.envrc` values and fill in a `.env.private` file (git-ignored):

```bash
# .env.private
export TF_VAR_statefile_postgresql_uri="postgresql://user:pass@localhost:5432/terraform"
export TF_VAR_openbao_token="s.xxxxxxxxxxxx"
```

```bash
direnv allow
```

### 2. Start the state backend port-forward

The Terraform state is stored in a CNPG PostgreSQL cluster running inside Kubernetes. Run this in a separate terminal before any Tofu command:

```bash
task pf
```

### 3. Apply

```bash
tofu init
tofu plan
tofu apply
```

### Adding a new namespace

Add the namespace name to `namespaces` in `terraform.tfvars`, then re-run `tofu apply`. If the namespace also needs access to shared secrets, add it to `namespaces_with_shared_access` as well.

## Design decisions

**One KV mount per namespace** — isolating secrets at the mount level (rather than using path prefixes in a shared mount) means a policy misconfiguration cannot leak secrets from one namespace to another. Each workload is only ever aware of its own mount path.

**Kubernetes auth with service account binding** — pods authenticate using their projected service account token. No static credentials are distributed to workloads; tokens are short-lived (1h TTL, 2h max). The expected service account name is `sa-vault-<namespace>`, which must be created in the cluster separately (via GitOps).

**Shared KV as opt-in** — the shared mount exists but namespaces only receive access to it when explicitly listed in `namespaces_with_shared_access`. The default is no shared access, following least-privilege.

**PostgreSQL remote state** — state is stored in a CNPG cluster co-located with the workloads it manages. This avoids an S3 bucket or external object store and keeps all homelab state inside the cluster. The port-forward requirement is the trade-off: `tofu` cannot run fully unattended without a running port-forward.

**OpenBao over HashiCorp Vault** — OpenBao is the Open-Source fork of Vault maintained by the Linux Foundation. It is API-compatible with the `hashicorp/vault` Terraform provider, so no provider changes were needed.
