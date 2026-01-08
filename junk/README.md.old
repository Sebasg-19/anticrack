# Anticrack

Suite of bash scripts to block major tech companies and countries' domains, IPs, services, tracking, and software on Linux systems. Prevents surveillance, adware, and asset operation from Google, Microsoft, Amazon, Meta, Apple, Netflix, Nigeria, Russia, China, Iran, Venezuela, Mexico, Canada, France.

## Overview

Each script targets one entity:

- `anticrack-google.sh`: Blocks Google domains (e.g., google.com, doubleclick.net), IP ranges, removes packages (e.g., google-chrome-stable, chromium), sets non-Google DNS.

- `anticrack-microsoft.sh`: Blocks Microsoft domains (e.g., telemetry, azure), IP ranges, removes packages (e.g., microsoft-edge-stable, teams, code), sets non-Microsoft DNS.

- `anticrack-amazon.sh`: Blocks Amazon domains (e.g., AWS trackers), IP ranges, removes packages (e.g., aws-cli), sets non-Amazon DNS.

- `anticrack-meta.sh`: Blocks Meta domains (e.g., facebook.com, instagram.com), IP ranges, removes packages (e.g., meta*, facebook*), sets non-Meta DNS.

- `anticrack-apple.sh`: Blocks Apple domains (e.g., apple.com trackers), IP ranges, removes packages (e.g., apple*), sets non-Apple DNS.

- `anticrack-netflix.sh`: Blocks Netflix domains, IP ranges, removes packages (e.g., netflix*), sets non-Netflix DNS.

- `anticrack-nigeria.sh`: Blocks Nigeria IP ranges, scam domains, removes packages (e.g., nigeria*), sets non-default DNS.

- `anticrack-russia.sh`: Blocks Russia IP ranges, phishing domains, removes packages (e.g., russia*), sets non-default DNS.

- `anticrack-china.sh`: Blocks China domains, IP ranges, removes packages (e.g., china*), sets non-default DNS.

- `anticrack-iran.sh`: Blocks Iran domains, IP ranges, removes packages (e.g., iran*), sets non-default DNS.

- `anticrack-venezuela.sh`: Blocks Venezuela IP ranges, scam domains, removes packages (e.g., venezuela*), sets non-default DNS.

- `anticrack-mexico.sh`: Blocks Mexico IP ranges, scam domains, removes packages (e.g., mexico*), sets non-default DNS.

- `anticrack-canada.sh`: Blocks Canada IP ranges, scam domains, removes packages (e.g., canada*), sets non-default DNS.

- `anticrack-france.sh`: Blocks France IP ranges, scam domains, removes packages (e.g., france*), sets non-default DNS.

Scripts use /etc/hosts for domain redirection to 0.0.0.0, iptables for IP blocking, apt for package purge. Toggleable with enable/disable commands.

![gaj](https://github.com/user-attachments/assets/673bd551-b7c6-45a0-9946-96acfcf8b092)

## Requirements

- Linux.

- Root access.

- Dependencies: curl, jq (for JSON parsing), iptables.

- Install jq: `sudo apt install jq`.

## Usage

Run as root: `./anticrack-[entity].sh enable` or `./anticrack-[entity].sh disable`.

Backup hosts and iptables before enabling.

Update periodically for new domains/IPs.

Test in VM; may break hosted sites or legitimate traffic.

<img src="https://github.com/user-attachments/assets/90352cdc-f111-42aa-9152-1188e91821b4" width="500">

## License

GPL-3.0
