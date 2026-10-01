# 02 · Create the VM and install Wazuh

All values in `${LIKE_THIS}` come from your `.env` (copy `.env.example`).

## 1. Upload the Ubuntu ISO

1. In the Proxmox web UI, select `${WAZUH_NODE}` → `${ISO_STORAGE}` → **ISO Images** → **Download from URL**.
2. Paste the Ubuntu Server 24.04 ISO link from ubuntu.com and click **Query URL**, then **Download**.

## 2. Create the VM

Either click through **Create VM** with the settings below, or run [`scripts/create-wazuh-vm.sh`](../scripts/create-wazuh-vm.sh) on the node.

| Setting | Value |
|---|---|
| OS | Ubuntu 24.04 ISO, type Linux 6.x |
| System | Machine q35, BIOS OVMF (UEFI) + EFI disk, **QEMU Agent: on** |
| Disk | 80 GB, SCSI, VirtIO SCSI single, IO thread on, discard on |
| CPU | 4 cores, type `host` |
| Memory | 8192 MB, **ballooning off** (OpenSearch doesn't like memory being reclaimed) |
| Network | `vmbr0`, VirtIO |
| Options | Start at boot: yes |

## 3. Install Ubuntu Server

- **Network screen:** set the static IP here (`${WAZUH_IP}`/24, gateway `${GATEWAY_IP}`). Doing it in the installer avoids netplan/cloud-init conflicts later.
- **Storage:** use the entire disk, and **untick LVM**. Proxmox already handles snapshots.
- **Profile:** create your admin user.
- **SSH:** tick **Install OpenSSH server**.
- **Snaps:** skip them all.

After the first boot:

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
sudo timedatectl set-timezone America/New_York   # alerts are only useful with correct time
```

**Take a snapshot now** in Proxmox (VM → Snapshots → "clean-os"). If the Wazuh install goes wrong, roll back and try again.

## 4. Install Wazuh (all-in-one)

Check the [quickstart](https://documentation.wazuh.com/current/quickstart.html) for the current version, then run:

```bash
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
sudo bash ./wazuh-install.sh -a
```

- It takes 10–20 minutes.
- At the end it prints the **admin** password and writes every service password to `wazuh-install-files.tar`.
- Copy the passwords into your password manager, then move the tar somewhere safe (not your repo; it's in `.gitignore` for a reason):

```bash
sudo tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt
```

Open `https://${WAZUH_IP}` and log in as `admin`. The certificate warning is expected, because it's self-signed.

## 5. Harden it

```bash
# Firewall: only your LAN (and Tailscale, if used) can reach Wazuh
sudo ufw default deny incoming
sudo ufw allow from ${LAN_CIDR} to any port 22,443,1514,1515,55000 proto tcp
# sudo ufw allow in on tailscale0      # optional: dashboard over Tailscale
sudo ufw enable

# Stop apt from upgrading Wazuh by surprise (upgrade deliberately; see docs/07)
sudo sed -i 's/^deb /#deb /' /etc/apt/sources.list.d/wazuh.list && sudo apt update
```

Other hardening steps:

- Create a named dashboard user for yourself (**☰ → Indexer management → Security → Internal users**) and stop using `admin` day to day.
- Never port-forward 443, 1514 or 1515 on your router.

## 6. Checkpoint

- [ ] The dashboard loads, and **Overview** shows the manager as healthy
- [ ] `sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard` shows all three **active**
- [ ] Wazuh VM added to your nightly Proxmox backup job
- [ ] Snapshot "wazuh-installed" taken
