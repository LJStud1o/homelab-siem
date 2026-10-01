# 06 · Optional: Wazuh alerts in Grafana

Prometheus and Grafana handle **metrics** (CPU, RAM, disk). Wazuh handles **security events**. They complement each other, and Wazuh doesn't replace them.

If Grafana is your "single pane of glass", you can add Wazuh alert counts next to your host metrics. Triage still happens in the Wazuh dashboard.

## 1. Create a read-only indexer user

In the Wazuh dashboard, go to **☰ → Indexer management → Security**:

1. **Roles → Create role** `grafana_read`:
   - Cluster permissions: `cluster_composite_ops_ro`
   - Index permissions: index pattern `wazuh-alerts-*`, action groups `read`, `search`
2. **Internal users → Create** a user `grafana` with a strong password.
3. Map the user to `grafana_read`.

## 2. Allow Grafana to reach the indexer (port 9200)

The indexer normally listens on localhost only in an all-in-one install. Check with:

```bash
sudo ss -tlnp | grep 9200
```

If it does, either leave it that way and skip this guide, or bind it to the LAN and firewall it to **only** Grafana's IP:

```bash
sudo ufw allow from <grafana-ip> to any port 9200 proto tcp
```

## 3. Add the data source

1. In Grafana: **Connections → Add new connection → OpenSearch**. Install the plugin if prompted.
2. Settings:
   - URL: `https://<wazuh-ip>:9200`
   - Basic auth: the `grafana` user
   - **Skip TLS verify:** on (the certificate is self-signed)
   - Index name: `wazuh-alerts-*`
   - Time field: `timestamp`

## 4. Useful panels

| Panel | Query / grouping |
|---|---|
| Alerts over time by severity | Count, group by `rule.level` (bucketed: 3–6, 7–9, 10+) |
| Top 10 rules this week | Terms on `rule.description` |
| Alerts by agent | Terms on `agent.name` |
| Suricata signatures | Filter `rule.groups:suricata`, terms on `data.alert.signature` |
