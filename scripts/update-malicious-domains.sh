#!/usr/bin/env bash
# Refresh the "malicious-domains" CDB list from the URLhaus host feed. Run as root on the Wazuh server.
# Schedule weekly:  echo "0 4 * * 0 root bash /opt/homelab-siem/scripts/update-malicious-domains.sh" > /etc/cron.d/wazuh-threatintel
set -euo pipefail

FEED="https://urlhaus.abuse.ch/downloads/hostfile/"
LIST=/var/ossec/etc/lists/malicious-domains
TMP=$(mktemp)

curl -fsSL "$FEED" \
  | awk '!/^#/ && NF>=2 {print $2}' \
  | grep -E '^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' \
  | sort -u | sed 's/$/:/' > "$TMP"

count=$(wc -l < "$TMP")
if [ "$count" -lt 100 ]; then
  echo "Feed returned only $count domains. Keeping the old list."; rm -f "$TMP"; exit 1
fi

install -o wazuh -g wazuh -m 660 "$TMP" "$LIST"
rm -f "$TMP"
systemctl restart wazuh-manager
echo "Loaded $count domains into $LIST"
