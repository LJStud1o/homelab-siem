# 08 · Publishing this repo safely

A homelab repo is public forever: forks, caches and archive sites keep copies even after you delete it. Publish **how you built it**, never **where it lives or how to get in**.

## Never publish

| Category | Examples | Use instead |
|---|---|---|
| Your public IP / ISP details | WAN IP, ISP name, router model + firmware | Leave it out |
| Real internal addressing | Your actual subnet, IP-to-service map | `10.0.0.x` placeholders from `.env.example` |
| Credentials | Passwords, API tokens, `wazuh-install-files.tar`, `client.keys`, SSH keys | Password manager only |
| Unique identifiers | MAC addresses, device serials, Tailscale tailnet name / 100.x IPs | Leave it out |
| Open inbound ports | Port-forward rules (e.g. game servers) | Leave it out |
| Personal data | Real usernames, household device names, email, DNS query logs | Generic names (`laptop-01`) |
| Live exports | Raw alerts, `.ndjson`, `.pcap`, unredacted screenshots | Redacted samples only |

## Before every push

```bash
bash scripts/precommit-check.sh     # scans for IPs, MACs, keys, tailnet names, emails
git diff --cached                   # read what you're about to publish
```

The GitHub Action in `.github/workflows/secret-scan.yml` runs **gitleaks** on every push as a second safety net.

## If you commit a secret anyway

1. **Rotate it first.** Assume it's already been scraped; bots scan new GitHub commits within minutes.
2. Then remove it from history (`git filter-repo` or BFG), and force-push.
3. Deleting the file in a new commit is **not** enough. The old commit still contains it.

## Screenshots

Before you commit or post a screenshot, check it for:

- [ ] Browser address bar: crop it, or it shows the IP and port
- [ ] Agent list: IPs and hostnames. Rename agents generically, or blur
- [ ] Alert details: `srcip`, `dstuser`, `full_log`. Blur these
- [ ] Tabs, bookmarks and the OS taskbar: crop them
- [ ] Notification pop-ups: turn on Do Not Disturb before capturing

Blur with a **solid box**, never a light Gaussian blur. Pixelated text can sometimes be reconstructed.

## Push to GitHub

```bash
git init -b main
git add .
bash scripts/precommit-check.sh && git commit -m "Initial homelab SIEM build guide"
gh repo create homelab-siem --public --source . --push     # or create it on github.com and add the remote
```

In **Repo → Settings → Code security**, enable **Secret scanning** and **Push protection** (free for public repos).
