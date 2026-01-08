#!/bin/bash

DOMAINS_URL="https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
IP_JSON_URL="https://download.microsoft.com/download/7/1/d/71d86715-5596-4529-9b13-da13a5de5b63/ServiceTags_Public_20260105.json"
HOSTS_FILE="/etc/hosts"
HOSTS_BACKUP="/etc/hosts.bak"
IPTABLES_BACKUP="/etc/iptables.bak"

function enable() {
  cp $HOSTS_FILE $HOSTS_BACKUP
  iptables-save > $IPTABLES_BACKUP

  # Download and block domains
  curl -s $DOMAINS_URL | grep -v '^#' | awk '{print $2}' | sed 's/^/0.0.0.0 /' >> $HOSTS_FILE

  # Block IP ranges (IPv4 only)
  IPS=$(curl -s $IP_JSON_URL | jq -r '.values[].properties.addressPrefixes[] | select(contains(":")|not)')
  for ip in $IPS; do
    iptables -A INPUT -s $ip -j DROP
    iptables -A OUTPUT -d $ip -j DROP
  done

  # Remove Microsoft packages
  apt purge -y microsoft* azure* edge* teams skype* code 2>/dev/null

  # Set non-Microsoft DNS
  echo "nameserver 9.9.9.9" > /etc/resolv.conf

  echo "Microsoft blocked."
}

function disable() {
  cp $HOSTS_BACKUP $HOSTS_FILE
  iptables-restore < $IPTABLES_BACKUP
  echo "nameserver 8.8.8.8" > /etc/resolv.conf  # Restore example
  echo "Microsoft unblocked."
}

case $1 in
  enable) enable ;;
  disable) disable ;;
  *) echo "Usage: $0 enable|disable" ;;
esac
