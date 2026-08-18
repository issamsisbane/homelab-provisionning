# Ansible

Deploys and configures the `ihcluster` Kubernetes cluster using [Kubespray](https://github.com/kubernetes-sigs/kubespray) and installs Tailscale on all nodes.

## Cluster topology

| Node | Control plane | etcd | Worker |
|------|:---:|:---:|:---:|
| ih-node-1 | | | ✓ |
| ih-node-2 | | | ✓ |
| ih-node-3 | ✓ | ✓ | ✓ |
| ih-node-4 | | | ✓ |

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

To scale the cluster (add/remove nodes) or tear it down, Kubespray's own playbooks are exposed as one-liners:

```bash
# Add nodes present in the inventory but not yet part of the cluster
ansible-playbook playbooks/scale.yml

# Remove Kubernetes from all nodes (does not touch Tailscale)
ansible-playbook playbooks/reset.yml
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

#### No lid suspend

The cluster nodes are laptops. By default, closing the lid triggers a suspend/shutdown via `systemd-logind`, which would take a node down. This playbook sets `HandleLidSwitch(Docked/ExternalPower)=ignore` in `/etc/systemd/logind.conf` and masks the `sleep`/`suspend`/`hibernate`/`hybrid-sleep` systemd targets so the node stays up regardless of lid state.

```bash
ansible-playbook playbooks/no_lid_suspend.yml
```

### Development container

A `.devcontainer/` is provided for running Ansible inside Docker (Ubuntu 24.04 with Ansible, ansible-lint, and common collections pre-installed). Open the `ansible/` folder in VS Code and reopen in container.

## Design decisions

**Kubespray over kubeadm directly** — Kubespray wraps kubeadm with Ansible, making the full cluster lifecycle (install, upgrade, scale) repeatable without manual steps. The version is pinned (`v2.30.0`) to keep cluster upgrades explicit.

**Single control plane node** — a 3-node homelab does not need HA control plane. Adding a second control plane would consume a node that is more useful as a worker, and the cluster can be redeployed from scratch if `ih-node-1` is lost. Same for etcd. The homelab doesn't need HA so I stick to backup the etcd database and restore if any disaster.

**Tailscale as a separate playbook** — Tailscale is not a Kubespray concern. Keeping it as a standalone role and playbook means it can be re-run independently (e.g. to rotate the auth key) without touching the cluster.

**Ansible Vault for secrets** — the Tailscale auth key is the only secret managed in Ansible. It is encrypted with Ansible Vault and committed to the repo, keeping secrets alongside the code that uses them without exposing them in plaintext.

**Lid handling as a separate playbook** — since the nodes are repurposed laptops, `systemd-logind`'s default lid behavior would suspend/shut down a node whenever its lid is closed. This is host-level OS configuration, unrelated to Kubespray or Tailscale, so it lives in its own role/playbook (`no_lid_suspend`) that can be re-applied independently, e.g. after an OS reinstall.
