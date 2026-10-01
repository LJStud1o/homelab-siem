#!/usr/bin/env bash
# Scan staged (or all tracked) files for things that should never be published.
# Usage: bash scripts/precommit-check.sh        (exit 1 if anything is found)
set -uo pipefail

if git rev-parse --git-dir >/dev/null 2>&1 && [ -n "$(git diff --cached --name-only)" ]; then
  FILES=$(git diff --cached --name-only --diff-filter=ACM)
else
  FILES=$(git ls-files 2>/dev/null || find . -type f -not -path './.git/*')
fi
[ -z "$FILES" ] && { echo "Nothing to scan."; exit 0; }

fail=0
check() { # $1 = label, $2 = regex
  local hits
  hits=$(echo "$FILES" | xargs grep -nIE "$2" 2>/dev/null | grep -v 'precommit-check.sh')
  if [ -n "$hits" ]; then echo -e "\n[!] $1:\n$hits"; fail=1; fi
}

# Private IPs OTHER than the 10.0.0.x placeholder range used in this repo
check "Real-looking private IP addresses" '\b(192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|10\.([1-9][0-9]?|1[0-9]{2}|2[0-5]{2})\.[0-9]{1,3}\.[0-9]{1,3})\b'
check "Tailscale addresses / tailnet names" '\b100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}\b|\.ts\.net\b'
check "MAC addresses" '\b([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}\b'
check "Private keys" '-----BEGIN [A-Z ]*PRIVATE KEY-----'
check "Password / token assignments" '(password|passwd|secret|token|api_key)\s*[:=]\s*["'"'"']?[A-Za-z0-9!@#$%^&*._-]{6,}'
check "Email addresses" '[A-Za-z0-9._%+-]+@(gmail|outlook|hotmail|yahoo|icloud)\.com'

if [ $fail -eq 1 ]; then
  echo -e "\nFix or redact the lines above before committing."
  exit 1
fi
echo "Clean: no IPs, MACs, keys, tailnet names or personal emails found."
