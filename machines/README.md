# Machines

Ubuntu autoinstall configuration for bare-metal node provisioning. Provides a `user-data` cloud-init file that installs Ubuntu unattended when booted from a USB drive.

## What it configures

- **Locale**: `fr_FR.UTF-8`, keyboard `us-intl`
- **User**: `kuadm` with passwordless sudo and SSH key authentication (password login disabled)
- **Storage**: direct layout (whole-disk, no LVM)
- **WiFi**: WPA2 via `wpa_supplicant` and a Netplan config written at install time
- **Boot**: traditional interface names disabled (`net.ifnames=0 biosdevname=0`) to get stable names (`eth0`, `wlan0`)

## How to run

### 1. Prepare the USB installer

Download an Ubuntu Server 24.04+ ISO and write it to a USB drive. Then place `user-data` at the root of the USB so the Ubuntu installer picks it up automatically at boot.

Alternatively, serve `user-data` over HTTP and pass `autoinstall ds=nocloud-net;s=http://<your-server>/` as a kernel parameter.

### 2. Customize before use

Before booting, edit `user-data` and replace the placeholder values:

| Field | Location | What to set |
|-------|----------|-------------|
| `hostname` | `identity.hostname` | `ih-node-1`, `ih-node-2`, or `ih-node-3` |
| `password` | `identity.password` | Output of `openssl passwd -6` |
| `authorized-keys` | `ssh.authorized-keys` | Your SSH public key |
| WiFi SSID | `write_files` netplan section | Your router name |
| WiFi password | `write_files` netplan section | Your WiFi password |

### 3. Boot and wait

Boot the node from USB. The installer runs fully unattended and reboots when done. The node is then reachable via SSH as `kuadm@<hostname>`.

## Design decisions

**Ubuntu autoinstall (cloud-init)** — the built-in Ubuntu unattended installer requires no external tooling (no PXE server, no DHCP config). A single `user-data` file on the USB is enough to fully automate a bare-metal install.

**`kuadm` as the system user** — a dedicated non-root user with passwordless sudo is what Kubespray expects. Using a consistent username across all nodes simplifies the Ansible inventory.

**WiFi-first networking** — the nodes are on a home WiFi network with no wired switch. The Netplan config and `wpasupplicant` package are included in the install so the node is network-reachable immediately after reboot, with no manual setup.

**Predictable interface names disabled** — `net.ifnames=0 biosdevname=0` restores `eth0`/`wlan0` naming. Kubespray and some CNI plugins are sensitive to interface name patterns; predictable names like `enp3s0` vary by hardware and would require per-node inventory customization.

**Single `user-data` file** — all three nodes use the same file with only the `hostname` changed. This is intentional: keeping a single template makes it obvious what differs between nodes and avoids maintaining three near-identical files.
