#!/usr/bin/env bash
# Install and enroll a Wazuh agent on Debian/Ubuntu/Proxmox. Run as root.
# Usage: WAZUH_MANAGER=10.0.0.12 [AGENT_GROUP=proxmox] [AGENT_NAME=pve1] bash install-agent-linux.sh
set -euo pipefail

: "${WAZUH_MANAGER:?Set WAZUH_MANAGER to the Wazuh server IP}"
AGENT_GROUP="${AGENT_GROUP:-default}"
AGENT_NAME="${AGENT_NAME:-$(hostname -s)}"

apt-get install -y gnupg apt-transport-https curl
curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH \
  | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  > /etc/apt/sources.list.d/wazuh.list
apt-get update

WAZUH_MANAGER="$WAZUH_MANAGER" WAZUH_AGENT_GROUP="$AGENT_GROUP" WAZUH_AGENT_NAME="$AGENT_NAME" \
  apt-get install -y wazuh-agent

systemctl daemon-reload
systemctl enable --now wazuh-agent

# Freeze the version: upgrade agents deliberately from the dashboard (docs/07)
sed -i 's/^deb /#deb /' /etc/apt/sources.list.d/wazuh.list
apt-get update -qq

sleep 5
systemctl --no-pager status wazuh-agent | head -3
grep -iE "connected|error" /var/ossec/logs/ossec.log | tail -3 || true
echo "Done. Check the dashboard: Agents > $AGENT_NAME should be Active (group: $AGENT_GROUP)."
