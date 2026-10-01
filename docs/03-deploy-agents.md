# 03 · Deploy agents

An agent ships logs, file-integrity events and a software inventory to the manager over an encrypted channel on 1514/tcp.

> The easiest way to get install commands is the dashboard's **Agents → Deploy new agent** wizard, which generates the exact command for each OS. The scripts in this repo do the same thing and are version-controlled.

## Linux (Proxmox nodes, Debian/Ubuntu VMs and LXCs)

On each host, as root:

```bash
WAZUH_MANAGER=10.0.0.12 AGENT_GROUP=proxmox bash scripts/install-agent-linux.sh
```

The script adds the Wazuh apt repo, installs the agent pointed at your manager, starts it, and then disables the repo so routine `apt upgrade` runs don't change the agent version.

**Suggested agent groups:**

| Group | Members | Why |
|---|---|---|
| `proxmox` | all Proxmox nodes | Shared FIM on `/etc/pve` and `/etc/ssh` (see below) |
| `sensor` | the Suricata node | Suricata `eve.json` collection |
| `dns` | the AdGuard container | DNS query log collection |
| `default` | everything else | Standard Linux monitoring |

Create the groups in **Agents management → Groups**, and put the shared configuration there. That way you edit one file instead of every host's `ossec.conf`.

### Group config: `proxmox`

Paste [`config/agent/group-proxmox.xml`](../config/agent/group-proxmox.xml) into the group's `agent.conf`. It adds:

- FIM on `/etc/ssh`, `/etc/network/interfaces` and `/root/.ssh` (real time) and `/etc/pve` (every 15 minutes, because realtime monitoring doesn't work on its FUSE filesystem)
- Collection of the Proxmox web UI access log (`/var/log/pveproxy/access.log`)

### Unprivileged LXCs

The agent runs fine inside unprivileged Debian or Ubuntu containers.

- **Expect gaps:** some syscheck and inventory data (kernel, hardware) reflects the host rather than the container.
- **For the host itself,** rely on the agent on the Proxmox node.

## Windows laptop

In an elevated PowerShell:

```powershell
.\scripts\install-agent-windows.ps1 -Manager 10.0.0.12
```

- Installs the MSI silently and starts the `WazuhSvc` service.
- By default it collects the Security, System and Application event logs.
- **Optional, for much better coverage:** install [Sysmon](https://learn.microsoft.com/sysinternals/downloads/sysmon) with a community config such as SwiftOnSecurity's, then add the Sysmon channel to the agent.

## Verify

- **Agents** page: every host shows **Active**.
- **Threat Hunting**, filtered by `agent.name:<host>`: events are arriving.
- **Vulnerability Detection**: results appear within about an hour of enrollment.

## Troubleshooting

| Symptom | Check |
|---|---|
| Agent never appears | `tail /var/ossec/logs/ossec.log` on the agent. Is 1515/tcp reachable? (`nc -vz 10.0.0.12 1515`) |
| Agent shows "Disconnected" | Is 1514/tcp reachable? Check the firewall (`ufw status`) on the manager |
| Duplicate agent names | Cloned VMs share `client.keys`. Remove the agent in the dashboard and re-enroll |
