#!/bin/bash

DOMAINS_URL="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/native.amazon.txt"
IP_JSON_URL="https://ip-ranges.amazonaws.com/ip-ranges.json"
HOSTS_FILE="/etc/hosts"
HOSTS_BACKUP="/etc/hosts.bak"
IPTABLES_BACKUP="/etc/iptables.bak"

function enable() {
  cp $HOSTS_FILE $HOSTS_BACKUP
  iptables-save > $IPTABLES_BACKUP

  # Download and block domains
  curl -s $DOMAINS_URL | grep -v '^#' | sed 's/^/0.0.0.0 /' >> $HOSTS_FILE

  # Block IP ranges (IPv4 only)
  IPS=$(curl -s $IP_JSON_URL | jq -r '.prefixes[].ip_prefix')
  for ip in $IPS; do
    iptables -A INPUT -s $ip -j DROP
    iptables -A OUTPUT -d $ip -j DROP
  done

  # Remove Amazon packages
  apt purge -y amazon* aws* 2>/dev/null

  # Set non-Amazon DNS
  echo "nameserver 9.9.9.9" > /etc/resolv.conf

  echo "Amazon blocked."
}

function disable() {
  cp $HOSTS_BACKUP $HOSTS_FILE
  iptables-restore < $IPTABLES_BACKUP
  echo "nameserver 8.8.8.8" > /etc/resolv.conf  # Restore example
  echo "Amazon unblocked."
}

case $1 in
  enable) enable ;;
  disable) disable ;;
  *) echo "Usage: $0 enable|disable" ;;
esac
