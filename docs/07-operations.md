# 07 · Operations: retention, backups, updates

## Retention: keep 90 days of alerts

Without a retention policy, the indexer fills the disk and stops accepting data.

1. Go to **☰ → Indexer management → Dev Tools**.
2. Paste the contents of [`config/indexer/ism-retention-90d.json`](../config/indexer/ism-retention-90d.json) and run it.

After that, new `wazuh-alerts-*` indices are deleted automatically once they're 90 days old.

**To apply the policy to indices that already exist:** go to Index Management → Indices, select them, then Actions → Apply policy.

Check disk usage weekly for the first month:

```bash
df -h /
curl -sk -u admin https://localhost:9200/_cat/indices/wazuh-alerts-*?v\&s=index
# curl prompts for the admin password, so it never lands in your shell history
```

## Backups

- Add the Wazuh VM to the nightly Proxmox backup job, using **snapshot mode**.
- For a config-only backup (small and fast), save these to the NAS:

```bash
sudo tar czf wazuh-config-$(date +%F).tgz \
  /var/ossec/etc/ossec.conf /var/ossec/etc/rules /var/ossec/etc/decoders \
  /var/ossec/etc/lists /var/ossec/etc/shared /var/ossec/etc/client.keys
```

`client.keys` holds every agent's key. Treat that tarball as a secret.

## Updating Wazuh

Upgrade on purpose, never by accident. The install guide disables the repo for exactly this reason.

**Order: manager/indexer/dashboard first, then the agents.** Agents can't be newer than the manager.

1. Take a Proxmox snapshot of the Wazuh VM.
2. Read the release notes.
3. Re-enable the repo:
   ```bash
   sudo sed -i 's/^#deb /deb /' /etc/apt/sources.list.d/wazuh.list
   ```
4. Follow the official upgrade guide for your version, component by component.
5. Upgrade the agents from the dashboard: **Agents → select agents → Upgrade**.
6. Disable the repo again.

## Weekly 10-minute routine

- [ ] Any agents disconnected?
- [ ] Review level 10+ alerts from the past week
- [ ] Tune one noisy rule
- [ ] Check disk usage and the Vulnerability Detection summary
- [ ] Refresh the threat-intel list (cron does it; confirm it ran)
