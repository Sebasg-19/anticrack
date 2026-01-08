# Anticrack

Suite of bash scripts to block major tech companies' domains, IPs, services, tracking, and software on Debian Linux systems. Prevents surveillance, adware, and asset operation from Google, Microsoft, and Amazon.

## Overview

Each script targets one company:
- `anticrack-google.sh`: Blocks Google domains (e.g., google.com, doubleclick.net), IP ranges, removes packages (e.g., google-chrome-stable, chromium), sets non-Google DNS.
- `anticrack-microsoft.sh`: Blocks Microsoft domains (e.g., telemetry, azure), IP ranges, removes packages (e.g., microsoft-edge-stable, teams, code), sets non-Microsoft DNS.
- `anticrack-amazon.sh`: Blocks Amazon domains (e.g., AWS trackers), IP ranges, removes packages (e.g., aws-cli), sets non-Amazon DNS.

Scripts use /etc/hosts for domain redirection to 0.0.0.0, iptables for IP blocking, apt for package purge. Toggleable with enable/disable commands.

## Requirements

- Debian Linux.
- Root access.
- Dependencies: curl, jq (for JSON parsing), iptables.
- Install jq: `sudo apt install jq`.

## Usage

Run as root: `./anticrack-[company].sh enable` or `./anticrack-[company].sh disable`.

Backup hosts and iptables before enabling.

Update periodically for new domains/IPs.

Test in VM; may break AWS-hosted sites for Amazon blocker.
![image-21~2](https://github.com/user-attachments/assets/90352cdc-f111-42aa-9152-1188e91821b4)

## License

GPL-3.0
