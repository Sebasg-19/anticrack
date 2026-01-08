#!/bin/bash

DOMAINS_URL="https://raw.githubusercontent.com/nickspaargaren/no-google/master/pihole-google.txt"
IP_JSON_URL="https://www.gstatic.com/ipranges/goog.json"
HOSTS_FILE="/etc/hosts"
HOSTS_BACKUP="/etc/hosts.bak"
IPTABLES_BACKUP="/etc/iptables.bak"

function enable() {
  cp $HOSTS_FILE $HOSTS_BACKUP
  iptables-save > $IPTABLES_BACKUP

  # Download and block domains
  curl -s $DOMAINS_URL | sed 's/^/0.0.0.0 /' >> $HOSTS_FILE

  # Block IP ranges
  IPS=$(curl -s $IP_JSON_URL | grep 'ipv4Prefix' | cut -d '"' -f4)
  for ip in $IPS; do
    iptables -A INPUT -s $ip -j DROP
    iptables -A OUTPUT -d $ip -j DROP
  done

  # Remove Google packages
  apt purge -y google* chromium* widevine* 2>/dev/null

  # Set non-Google DNS
  echo "nameserver 9.9.9.9" > /etc/resolv.conf

  echo "Google blocked."
}

function disable() {
  cp $HOSTS_BACKUP $HOSTS_FILE
  iptables-restore < $IPTABLES_BACKUP
  echo "nameserver 8.8.8.8" > /etc/resolv.conf  # Restore example
  echo "Google unblocked."
}

case $1 in
  enable) enable ;;
  disable) disable ;;
  *) echo "Usage: $0 enable|disable" ;;
esac
