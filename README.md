# Anticrack

Suite of bash scripts to block major tech companies, countries, domains, IPs, services, tracking, and software on Linux systems. Prevents surveillance, adware, and asset operation from enemies like Russia, China, Iran, North Korea, Belarus, Syria, Venezuela, Cuba, Pakistan, Cambodia, Myanmar, Nicaragua, Eritrea, Mali, Central African Republic, Burkina Faso, Niger, Greenland, and groups like NATO, BRICS.

## Overview

anticrack-beta0.sh: Initial beta unified script. Blocks enemy country IP ranges (IPv4/IPv6), DNS servers, domains (tech, social, media, military, foreign tech), TLDs (.ru, .cn, etc.), TOR/VPN exits, threats. Features: menu-driven interface, group blocking (enemies, allies, all_enemies, NATO, Greenland, India, BRICS, custom), domain/TLD/group management, Fail2Ban, Suricata, Snort IDS, rate limiting, logging, bridge blocking, whitelisting, cron updates, total lockdown.

Separate entity scripts (e.g., anticrack-google.sh) remain for targeted blocking: domains to 0.0.0.0, IP ranges via iptables, package removal, DNS changes. Toggle with enable/disable.

## Requirements

Linux.  
Root access.  
Dependencies: nftables, wget, netfilter-persistent, dnsmasq, fail2ban, suricata, curl, jq, tor, snort.  
Install: sudo apt install [dependencies].

## Usage

Run as root: `./anticrack-beta0.sh` for menu (enable/disable countries/groups/domains/DNS/TLDs/IDS/etc., status, lockdown).  
For entity scripts: `./anticrack-[entity].sh enable` or `disable`.  

Backup configs/iptables/nftables before use. Update threat lists periodically. Test in VM; may disrupt connectivity.
---
![armybanner](https://github.com/user-attachments/assets/12e92da4-1c24-4446-b0b9-08bfccb2cc59)
<img width="960" height="295" alt="ciasuper" src="https://github.com/user-attachments/assets/203c86fb-a11f-488f-b3f8-620978b4b6ae" />
![nwl](https://github.com/user-attachments/assets/0ec5c1d6-6c40-4743-832f-dad6e131f524)
![Elon-musk-blunt-780x405](https://github.com/user-attachments/assets/d8c5de7a-4736-468e-b6fc-e65fc2bcf6bc)
![3bb2a2f6-bfb8-41de-861e-007899426b92_text](https://github.com/user-attachments/assets/a4dc8489-ea59-412e-b708-a58e23a1d0bb)![samdreamsmaker-samuel-guizani](https://github.com/user-attachments/assets/0d1572fe-12ee-44d5-87e3-53ea2c52b2ec)![giphy](https://github.com/user-attachments/assets/01cdd6e4-0a52-4ebd-8992-3fb39176e0a0)![defcon](https://github.com/user-attachments/assets/3f296624-3b85-4e0e-bb00-0f1587ad08ba)
![linusfu](https://github.com/user-attachments/assets/e3344384-e2e5-4910-bcfc-1489f6c264f0)
## License
GPL-3.0
