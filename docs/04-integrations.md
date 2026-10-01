# 04 · Integrate Suricata, AdGuard and Proxmox logs

This is what turns "a bunch of agents" into a SIEM: network, DNS and hypervisor telemetry, all correlated in one place.

## Suricata (network IDS)

**Prerequisite:** Suricata is already running on the sensor node and reading a mirror/SPAN port. In this lab, the managed switch mirrors the router uplink and both other nodes into a dedicated NIC on node 3.

1. Put the sensor node's agent in the `sensor` group.
2. Paste [`config/agent/group-sensor.xml`](../config/agent/group-sensor.xml) into the group's `agent.conf`. That tells the agent to read `/var/log/suricata/eve.json`.
3. Wazuh already ships decoders and rules for Suricata (rules 86600–86604), so the manager needs no changes.
4. In **Threat Hunting**, filter `rule.groups:suricata`.

**Test** from any LAN machine:

```bash
curl http://testmynids.org/uid/index.html
```

This returns text that the Emerging Threats rule *"GPL ATTACK_RESPONSE id check returned root"* matches. It's harmless and exists specifically for testing an IDS.

> **Mirror-port gotcha:** the mirror NIC must come up at boot and be in promiscuous mode. NIC names can change when you add PCIe cards (for example `enp4s0f0` → `enp5s0f0` after installing a GPU). If Suricata goes quiet after hardware changes, run `ip -br link` first.

## AdGuard Home (DNS)

1. In AdGuard, go to **Settings → General settings** and make sure **query logs** are enabled.
2. Install the agent **inside the AdGuard container** and put it in the `dns` group.
3. Paste [`config/agent/group-dns.xml`](../config/agent/group-dns.xml) into the group's `agent.conf`.
4. Load the custom rules (below). AdGuard's JSON is decoded automatically, and rules 100300–100303 give it meaning.

## Proxmox hypervisor logs

The `proxmox` group config handles this:

- File integrity monitoring on `/etc/pve`, `/etc/ssh`, `/etc/network/interfaces` and `/root/.ssh`
- The web UI access log
- journald, which carries SSH logins, `pvedaemon` auth failures and sudo

## Load the custom rules and decoders

**Build the threat-intel list first** ([config/manager/lists](../config/manager/lists/README.md)). Rule 100303 references it, and the manager won't start if a rule points at a list that doesn't exist. To skip threat intel for now, delete rule 100303 from `local_rules.xml` instead.

Then, on the Wazuh VM:

```bash
sudo cp config/manager/rules/local_decoder.xml /var/ossec/etc/decoders/local_decoder.xml
sudo cp config/manager/rules/local_rules.xml   /var/ossec/etc/rules/local_rules.xml
sudo chown wazuh:wazuh /var/ossec/etc/decoders/local_decoder.xml /var/ossec/etc/rules/local_rules.xml
sudo /var/ossec/bin/wazuh-analysisd -t && sudo systemctl restart wazuh-manager
```

> If you've already customised `local_rules.xml`, **merge** these rules into it instead of overwriting the file.

### Test a rule without generating real attacks

```bash
sudo /var/ossec/bin/wazuh-logtest
```

Paste this line:

```
Sep 29 10:15:02 pve1 pvedaemon[1234]: authentication failure; rhost=::ffff:10.0.0.50 user=root@pam msg=Authentication failure
```

You should see decoder `pvedaemon`, `srcip: 10.0.0.50`, and rule **100100** firing.
