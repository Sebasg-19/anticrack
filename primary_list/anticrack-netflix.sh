#!/bin/bash

DOMAINS_URL="https://raw.githubusercontent.com/v2ray/domain-list-community/master/data/netflix"
IP_TXT_URL="https://raw.githubusercontent.com/Blankwonder/surge-list/master/netflix.list"
HOSTS_FILE="/etc/hosts"
HOSTS_BACKUP="/etc/hosts.bak"
IPTABLES_BACKUP="/etc/iptables.bak"

function enable() {
  cp $HOSTS_FILE $HOSTS_BACKUP
  iptables-save > $IPTABLES_BACKUP

  # Download and block domains
  curl -s $DOMAINS_URL | grep '^domain:' | sed 's/^domain:/0.0.0.0 /' >> $HOSTS_FILE

  # Block IP ranges (IPv4 only)
  IPS=$(curl -s $IP_TXT_URL | grep '^IP-CIDR,' | cut -d',' -f2)
  for ip in $IPS; do
    iptables -A INPUT -s $ip -j DROP
    iptables -A OUTPUT -d $ip -j DROP
  done

  # Remove Netflix packages
  apt purge -y netflix* 2>/dev/null

  # Set non-Netflix DNS
  echo "nameserver 9.9.9.9" > /etc/resolv.conf

  echo "Netflix blocked."
}

function disable() {
  cp $HOSTS_BACKUP $HOSTS_FILE
  iptables-restore < $IPTABLES_BACKUP
  echo "nameserver 8.8.8.8" > /etc/resolv.conf  # Restore example
  echo "Netflix unblocked."
}

case $1 in
  enable) enable ;;
  disable) disable ;;
  *) echo "Usage: $0 enable|disable" ;;
esac
