#!/usr/bin/env bash
# Create the Wazuh VM on a Proxmox node. Run as root ON the target node.
# Usage: set -a; source .env; set +a; bash scripts/create-wazuh-vm.sh
set -euo pipefail

: "${WAZUH_VMID:?set in .env}" "${WAZUH_STORAGE:?}" "${ISO_STORAGE:?}" "${UBUNTU_ISO:?}"

if qm status "$WAZUH_VMID" >/dev/null 2>&1; then
  echo "VM $WAZUH_VMID already exists. Pick another WAZUH_VMID."; exit 1
fi
pvesm list "$ISO_STORAGE" | grep -q "$UBUNTU_ISO" || { echo "ISO $UBUNTU_ISO not found on $ISO_STORAGE"; exit 1; }

qm create "$WAZUH_VMID" \
  --name wazuh \
  --ostype l26 \
  --machine q35 \
  --bios ovmf \
  --efidisk0 "$WAZUH_STORAGE":1,efitype=4m,pre-enrolled-keys=0 \
  --cpu host --cores 4 --sockets 1 \
  --memory 8192 --balloon 0 \
  --scsihw virtio-scsi-single \
  --scsi0 "$WAZUH_STORAGE":80,iothread=1,discard=on,ssd=1 \
  --ide2 "$ISO_STORAGE":iso/"$UBUNTU_ISO",media=cdrom \
  --boot order='scsi0;ide2' \
  --net0 virtio,bridge=vmbr0 \
  --agent enabled=1 \
  --onboot 1 \
  --tags siem

echo "Created VM $WAZUH_VMID. Start it and install Ubuntu (see docs/02):"
echo "  qm start $WAZUH_VMID"
