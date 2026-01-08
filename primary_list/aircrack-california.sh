#!/bin/bash

DOMAINS_URL="https://raw.githubusercontent.com/blocklistproject/Lists/master/scam.txt"
HOSTS_FILE="/etc/hosts"
HOSTS_BACKUP="/etc/hosts.bak"
IPTABLES_BACKUP="/etc/iptables.bak"

function enable() {
  cp $HOSTS_FILE $HOSTS_BACKUP
  iptables-save > $IPTABLES_BACKUP

  # Download and block domains
  curl -s $DOMAINS_URL | grep -v '^#' >> $HOSTS_FILE

  # Block IP ranges (IPv4 only)
  IPS="8.112.228.0/11 44.188.144.0/20 57.128.0.0/19 57.13.0.0/19 35.207.247.0/20"
  for ip in $IPS; do
    iptables -A INPUT -s $ip -j DROP
    iptables -A OUTPUT -d $ip -j DROP
  done

  # Remove related packages
  apt purge -y california* 2>/dev/null

  # Set non-default DNS
  echo "nameserver 9.9.9.9" > /etc/resolv.conf

  echo "California blocked."
}

function disable() {
  cp $HOSTS_BACKUP $HOSTS_FILE
  iptables-restore < $IPTABLES_BACKUP
  echo "nameserver 8.8.8.8" > /etc/resolv.conf  # Restore example
  echo "California unblocked."
}

case $1 in
  enable) enable ;;
  disable) disable ;;
  *) echo "Usage: $0 enable|disable" ;;
esac
