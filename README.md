# Anticrack

Suite of bash scripts to block major tech companies' domains, IPs, services, tracking, and software on Debian Linux systems. Prevents surveillance, adware, and asset operation from Google, Microsoft, Amazon, and Facebook.

## Overview

Each script targets one company:
- `anticrack-google.sh`: Blocks Google domains (e.g., google.com, doubleclick.net), IP ranges, removes packages (e.g., google-chrome-stable, chromium), sets non-Google DNS.

- `anticrack-microsoft.sh`: Blocks Microsoft domains (e.g., telemetry, azure), IP ranges, removes packages (e.g., microsoft-edge-stable, teams, code), sets non-Microsoft DNS.

- `anticrack-amazon.sh`: Blocks Amazon domains (e.g., AWS trackers), IP ranges, removes packages (e.g., aws-cli), sets non-Amazon DNS.

- `anticrack-facebook.sh`: Blocks Meta domains (e.g., facebook.com, instagram.com), IP ranges, removes packages (e.g., meta*, facebook*), sets non-Meta DNS.

Scripts use /etc/hosts for domain redirection to 0.0.0.0, iptables for IP blocking, apt for package purge. Toggleable with enable/disable commands.

![gaj](https://github.com/user-attachments/assets/673bd551-b7c6-45a0-9946-96acfcf8b092)


## Requirements

- Linux.
- Root access.
- Dependencies: curl, jq (for JSON parsing), iptables.
- Install jq: `sudo apt install jq`.

## Usage

Run as root: `./anticrack-[company].sh enable` or `./anticrack-[company].sh disable`.

Backup hosts and iptables before enabling.

Update periodically for new domains/IPs.

Test in VM; may break AWS-hosted sites for Amazon blocker.

![image-21~2(1)](https://github.com/user-attachments/assets/4bad3aa0-85f6-407c-bf10-798a40ebc391)

## License

GPL-3.0
