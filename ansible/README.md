# Ansible

Deploys and configures the `ihcluster` Kubernetes cluster using [Kubespray](https://github.com/kubernetes-sigs/kubespray) and installs Tailscale on all nodes.

## Cluster topology

| Node | Control plane | etcd | Worker |
|------|:---:|:---:|:---:|
| ih-node-1 | ✓ | ✓ | ✓ |
| ih-node-2 | | | ✓ |
| ih-node-3 | | | ✓ |

- **CNI**: Calico
- **Service CIDR**: `10.233.0.0/18`
- **Pod CIDR**: `10.233.64.0/18` (`/24` per node)
- **SSH user**: `kuadm`

## How to run

### 1. Install dependencies

```bash
ansible-galaxy install -r requirements.yml
```

### 2. Deploy the Kubernetes cluster

```bash
ansible-playbook playbooks/kubespray.yml
```

### 3. Install Tailscale on all nodes

The Tailscale auth key is stored in `vars/tailscale.yml` as an Ansible Vault-encrypted file.

```bash
ansible-playbook playbooks/tailscale.yml --ask-vault-pass
```

### Operational playbooks

#### UP

```bash
# Verify all nodes are reachable
ansible-playbook playbooks/up.yml
```

#### Inventory

```bash
# Report CPU / memory / disk capacity per node
ansible-playbook playbooks/inventory_cluster.yml
```

#### Shutdown

```bash
# Gracefully shut down all nodes
ansible-playbook playbooks/shutdown.yml
```

### Development container

A `.devcontainer/` is provided for running Ansible inside Docker (Ubuntu 24.04 with Ansible, ansible-lint, and common collections pre-installed). Open the `ansible/` folder in VS Code and reopen in container.

## Design decisions

**Kubespray over kubeadm directly** — Kubespray wraps kubeadm with Ansible, making the full cluster lifecycle (install, upgrade, scale) repeatable without manual steps. The version is pinned (`v2.30.0`) to keep cluster upgrades explicit.

**Single control plane node** — a 3-node homelab does not need HA control plane. Adding a second control plane would consume a node that is more useful as a worker, and the cluster can be redeployed from scratch if `ih-node-1` is lost. Same for etcd. The homelab doesn't need HA so I stick to backup the etcd database and restore if any disaster.

**Tailscale as a separate playbook** — Tailscale is not a Kubespray concern. Keeping it as a standalone role and playbook means it can be re-run independently (e.g. to rotate the auth key) without touching the cluster.

**Ansible Vault for secrets** — the Tailscale auth key is the only secret managed in Ansible. It is encrypted with Ansible Vault and committed to the repo, keeping secrets alongside the code that uses them without exposing them in plaintext.
