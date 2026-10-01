# 01 · Plan and size the build

## Why Wazuh?

Enterprise SIEMs (Splunk Enterprise Security, Microsoft Sentinel, Google SecOps) are either paid add-ons or cloud services billed per GB. Splunk Free is capped at 500 MB/day and has **no alerting**, so it can't act as a SIEM.

Wazuh is free and open source, and runs on-prem. It has the same moving parts as the enterprise tools:

| Component | Job |
|---|---|
| **Agent** | Runs on each host. Ships logs, file-integrity events and inventory. |
| **Server (manager)** | Decodes the logs and runs detection rules, producing alerts tagged with MITRE ATT&CK. |
| **Indexer** | OpenSearch. Stores alerts so they can be searched. |
| **Dashboard** | OpenSearch Dashboards with Wazuh apps, for triage, threat hunting and compliance views. |

## Where it runs

Choose the **least-loaded node**. In this lab that's node 2, which has no other guests.

| Resource | Wazuh minimum (all-in-one, 1–25 agents, 90 days) | This build |
|---|---|---|
| vCPU | 4 | 4 |
| RAM | 8 GB | 8 GB |
| Disk | 50 GB | 80 GB (room for Suricata alert volume) |
| OS | Ubuntu 24.04 / RHEL 9 / Amazon Linux | Ubuntu Server 24.04 LTS |

Use a **VM, not an LXC**. The indexer (OpenSearch) needs kernel settings such as `vm.max_map_count` that unprivileged containers can't set, and Wazuh officially supports VMs and bare metal.

## Network plan

| Port | Direction | Purpose |
|---|---|---|
| 1514/tcp | agents → Wazuh | Encrypted event stream |
| 1515/tcp | agents → Wazuh | Agent enrollment |
| 443/tcp | analyst → Wazuh | Dashboard |
| 55000/tcp | analyst → Wazuh | Wazuh API (optional) |
| 9200/tcp | local only | Indexer; never expose |

- **Nothing is port-forwarded from the internet.** For remote access, use Tailscale or another VPN.
- Give the VM a **static IP** plus a **DHCP reservation** on the router, so no other device can ever be handed that address.

## Data sources (in priority order)

1. **Proxmox hosts:** auth logs (SSH and web UI), file integrity on `/etc/pve` and `/etc/ssh`, and the package inventory for vulnerability detection.
2. **Suricata** on the sensor node, reading `eve.json` from a mirror/SPAN port.
3. **AdGuard Home** DNS query log.
4. **Guest VMs/LXCs** and the **Windows laptop**.

## Budget

$0 in software. Disk usage is roughly 0.5–1.5 GB/day, depending on how chatty Suricata is. Check it after the first week (see [07-operations](07-operations.md)).
