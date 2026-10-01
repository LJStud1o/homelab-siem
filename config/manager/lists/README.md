# Threat-intel CDB list

Rule `100303` looks up every DNS query in a Wazuh CDB list named `malicious-domains`.

## Build the list

On the manager, fill it from a free feed. This example uses the URLhaus host list:

```bash
sudo bash scripts/update-malicious-domains.sh
```

The script:

1. downloads the feed,
2. converts it to Wazuh's `key:` format (`badsite.example:`),
3. writes `/var/ossec/etc/lists/malicious-domains`, and
4. restarts the manager.

## Register it once

Add this line in `/var/ossec/etc/ossec.conf`, inside `<ruleset>`, next to the other `<list>` lines:

```xml
<list>etc/lists/malicious-domains</list>
```

## Test it

Add a fake entry such as `test-malware.example:` to the list, then look it up:

```bash
nslookup test-malware.example <adguard-ip>
```

Rule 100303 should fire. Remove the fake entry afterwards.

Schedule the script weekly with cron so the list stays current.
