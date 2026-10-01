# 05 · Detections and safe attack simulation

A SIEM you haven't tested is a SIEM you can't trust. Each test below is safe, only touches your own lab, and maps to a MITRE ATT&CK technique.

| # | Simulate | How | Expected alert | ATT&CK |
|---|---|---|---|---|
| 1 | SSH brute force | From your laptop, fail an SSH login to a test VM 8+ times: `for i in $(seq 8); do ssh fakeuser@<test-vm>; done` (just press Enter at each password prompt) | 5710 / 5712 "sshd: brute force" | T1110 |
| 2 | Proxmox web UI brute force | Enter a wrong password in the Proxmox login page 5 times | **100100**, then **100101** | T1110.001 |
| 3 | Credential file tampering | `echo "# test" >> /root/.ssh/authorized_keys` on a node, then remove the line | **100150** (level 12), within 15 min (next scheduled scan) | T1098.004 |
| 4 | Network IDS hit | `curl http://testmynids.org/uid/index.html` | 86601 "Suricata: Alert – GPL ATTACK_RESPONSE…" | T1033 |
| 5 | Malicious DNS lookup | Add `test-malware.example:` to the CDB list, then `nslookup test-malware.example <adguard-ip>` | **100303** | T1071.004 |
| 6 | New local account | `sudo useradd testuser && sudo userdel testuser` | 5902 "New user added" | T1136.001 |
| 7 | Vulnerable package | Nothing to do: check **Vulnerability Detection** | CVE list per agent | T1190 |

> Run tests only against machines you own. Don't point brute-force tools at your router or ISP gateway, which can lock you out.

## Triage workflow (the SOC loop)

1. **Detect.** The alert shows up on the dashboard (use the *Security events* or *Threat Hunting* view).
2. **Triage.** Is it real? Check `agent.name`, `data.srcip`, `rule.description` and the full log.
3. **Investigate.** Pivot: what else did this source IP or this host do in the last hour?
4. **Respond.** Block, patch, or rotate credentials. Wazuh *active response* can automate blocks. Start in alert-only mode.
5. **Tune.** If it was noise, write an exception rule (level 0, `if_sid` the noisy rule, match the benign condition). Never just delete rules.
6. **Document.** Keep a short incident note in `incidents/YYYY-MM-DD-title.md`, redacted per [08-publishing-safely](08-publishing-safely.md).

## Writing your own rules

- **IDs:** use the range 100000–120000.
- **Test first:** always test with `wazuh-logtest` before restarting the manager.
- **Levels:**
  - 0 = silent
  - 3 = informational (stored)
  - 7 = worth a look
  - 10+ = investigate now
  - 12+ = critical
- **Tag every rule with MITRE ATT&CK.** It makes the dashboard's MITRE view (and your LinkedIn screenshots) much more useful.
