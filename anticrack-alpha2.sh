#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "Run as root." 1>&2
   exit 1
fi

command -v ipset >/dev/null 2>&1 || apt install -y ipset
command -v wget >/dev/null 2>&1 || apt install -y wget

declare -A country_names
country_names=( [cn]="China" [ru]="Russia" [ir]="Iran" [kp]="North Korea" [by]="Belarus" [sy]="Syria" [ve]="Venezuela" [cu]="Cuba" [pk]="Pakistan" [kh]="Cambodia" [mm]="Myanmar" [ni]="Nicaragua" [er]="Eritrea" [ml]="Mali" [cf]="Central African Republic" [bf]="Burkina Faso" [ne]="Niger" [gl]="Greenland" )

countries=(cn ru ir kp by sy ve cu pk kh mm ni er ml cf bf ne gl)

declare -A groups
groups[enemies]="cn ru ir kp"
groups[allies]="by sy ve cu pk kh mm ni er ml cf bf ne"
groups[greenland]="gl"

dns_ips=("114.114.114.114" "114.114.115.115" "180.76.76.76" "223.5.5.5" "223.6.6.6" "77.88.8.1" "77.88.8.8" "77.88.8.88" "178.22.122.100" "185.51.200.2" "2.189.44.44" "81.91.144.116" "175.45.176.15" "175.45.176.16")

tech_domains=("google.com" "youtube.com" "facebook.com" "instagram.com" "amazon.com" "microsoft.com" "apple.com" "netflix.com" "x.com" "tiktok.com" "whatsapp.com" "linkedin.com" "yahoo.com" "baidu.com" "yandex.ru" "alibaba.com")

HOSTS_FILE="/etc/hosts"
BLOCK_MARKER="# AntiCrack Domain Block"
BLOCKED_DOMAINS_FILE="/tmp/anticrack_domains.txt"

function status_country() {
  local c=$1
  if ipset list "block-$c" >/dev/null 2>&1; then
    echo "Enabled"
  else
    echo "Disabled"
  fi
}

function enable_country() {
  local c=$1
  if [ "$(status_country $c)" == "Enabled" ]; then
    echo "${country_names[$c]} already enabled."
    return
  fi
  wget -q "https://www.ipdeny.com/ipblocks/data/aggregated/${c}-aggregated.zone" -O "/tmp/${c}.zone"
  ipset create "block-$c" hash:net
  while read -r ip; do
    ipset add "block-$c" "$ip"
  done < "/tmp/${c}.zone"
  rm "/tmp/${c}.zone"
  iptables -A INPUT -m set --match-set "block-$c" src -j DROP
  iptables -A OUTPUT -m set --match-set "block-$c" dst -j DROP
  echo "${country_names[$c]} enabled."
}

function disable_country() {
  local c=$1
  if [ "$(status_country $c)" == "Disabled" ]; then
    echo "${country_names[$c]} already disabled."
    return
  fi
  iptables -D INPUT -m set --match-set "block-$c" src -j DROP 2>/dev/null
  iptables -D OUTPUT -m set --match-set "block-$c" dst -j DROP 2>/dev/null
  ipset destroy "block-$c" 2>/dev/null
  echo "${country_names[$c]} disabled."
}

function enable_group() {
  local g=$1
  for c in ${groups[$g]}; do
    enable_country $c
  done
  echo "$g group enabled."
}

function disable_group() {
  local g=$1
  for c in ${groups[$g]}; do
    disable_country $c
  done
  echo "$g group disabled."
}

function status_dns() {
  if ipset list block-dns >/dev/null 2>&1; then
    echo "Enabled"
  else
    echo "Disabled"
  fi
}

function enable_dns_block() {
  if [ "$(status_dns)" == "Enabled" ]; then
    echo "DNS block already enabled."
    return
  fi
  ipset create block-dns hash:ip
  for ip in "${dns_ips[@]}"; do
    ipset add block-dns "$ip"
  done
  iptables -A INPUT -m set --match-set block-dns src -j DROP
  iptables -A OUTPUT -m set --match-set block-dns dst -j DROP
  echo "Enemy DNS blocked."
}

function disable_dns_block() {
  if [ "$(status_dns)" == "Disabled" ]; then
    echo "DNS block already disabled."
    return
  fi
  iptables -D INPUT -m set --match-set block-dns src -j DROP 2>/dev/null
  iptables -D OUTPUT -m set --match-set block-dns dst -j DROP 2>/dev/null
  ipset destroy block-dns 2>/dev/null
  echo "Enemy DNS unblocked."
}

function enable_tech_block() {
  for d in "${tech_domains[@]}"; do
    block_domain "$d"
  done
  echo "Tech companies blocked."
}

function disable_tech_block() {
  for d in "${tech_domains[@]}"; do
    unblock_domain "$d"
  done
  echo "Tech companies unblocked."
}

function status_tech() {
  local blocked=0
  local total=${#tech_domains[@]}
  for d in "${tech_domains[@]}"; do
    if [ "$(status_domain $d)" == "Blocked" ]; then
      ((blocked++))
    fi
  done
  if [ $blocked -eq $total ]; then
    echo "Enabled"
  elif [ $blocked -eq 0 ]; then
    echo "Disabled"
  else
    echo "Partial ($blocked/$total)"
  fi
}

function total_lockdown() {
  enable_group enemies
  enable_group allies
  enable_group greenland
  enable_dns_block
  enable_tech_block
  echo "Total lockdown enabled."
}

function list_status() {
  for c in "${countries[@]}"; do
    echo "${country_names[$c]} ($c): $(status_country $c) - Blocks IP traffic to/from ${country_names[$c]}."
  done
  echo "Enemy DNS: $(status_dns) - Blocks traffic to enemy DNS servers."
  echo "Tech Companies: $(status_tech) - Blocks major tech domains."
}

function status_domain() {
  local d=$1
  if grep -q "^0.0.0.0 $d $BLOCK_MARKER" "$HOSTS_FILE"; then
    echo "Blocked"
  else
    echo "Not blocked"
  fi
}

function block_domain() {
  local d=$1
  if [ "$(status_domain $d)" == "Blocked" ]; then
    echo "$d already blocked."
    return
  fi
  echo "0.0.0.0 $d $BLOCK_MARKER" >> "$HOSTS_FILE"
  echo "$d blocked."
}

function unblock_domain() {
  local d=$1
  if [ "$(status_domain $d)" == "Not blocked" ]; then
    echo "$d not blocked."
    return
  fi
  sed -i "/^0.0.0.0 $d $BLOCK_MARKER/d" "$HOSTS_FILE"
  echo "$d unblocked."
}

function list_blocked_domains() {
  grep "$BLOCK_MARKER" "$HOSTS_FILE" | awk '{print $2 " - Blocked domain."}' > "$BLOCKED_DOMAINS_FILE"
  if [ -s "$BLOCKED_DOMAINS_FILE" ]; then
    cat "$BLOCKED_DOMAINS_FILE"
  else
    echo "No domains blocked."
  fi
  rm -f "$BLOCKED_DOMAINS_FILE"
}

echo "AntiCrack Global Blocker"
echo "Secures US internet by blocking enemies in WW3."
echo "Warning: Root required. May break access. Backup configs. Use at own risk. Includes DNS and tech blocks for total lockdown."
echo "Uses ipset for efficiency."

while true; do
  echo "1) List status"
  echo "2) Enable country"
  echo "3) Disable country"
  echo "4) Status of country"
  echo "5) Enable group (enemies/allies/greenland)"
  echo "6) Disable group"
  echo "7) List blocked domains"
  echo "8) Block domain"
  echo "9) Unblock domain"
  echo "10) Status of domain"
  echo "11) Enable DNS block"
  echo "12) Disable DNS block"
  echo "13) Status of DNS block"
  echo "14) Enable tech block"
  echo "15) Disable tech block"
  echo "16) Status of tech block"
  echo "17) Total lockdown"
  echo "18) Exit"
  read -p "Choice: " choice
  case $choice in
    1) list_status ;;
    2) read -p "Country code: " code
       if [[ " ${countries[*]} " =~ " ${code} " ]]; then enable_country $code; else echo "Invalid."; fi ;;
    3) read -p "Country code: " code
       if [[ " ${countries[*]} " =~ " ${code} " ]]; then disable_country $code; else echo "Invalid."; fi ;;
    4) read -p "Country code: " code
       if [[ " ${countries[*]} " =~ " ${code} " ]]; then echo "${country_names[$code]}: $(status_country $code)"; else echo "Invalid."; fi ;;
    5) read -p "Group: " group
       if [[ -n "${groups[$group]}" ]]; then enable_group $group; else echo "Invalid."; fi ;;
    6) read -p "Group: " group
       if [[ -n "${groups[$group]}" ]]; then disable_group $group; else echo "Invalid."; fi ;;
    7) list_blocked_domains ;;
    8) read -p "Domain: " domain
       if [[ -n "$domain" ]]; then block_domain $domain; else echo "Invalid."; fi ;;
    9) read -p "Domain: " domain
       if [[ -n "$domain" ]]; then unblock_domain $domain; else echo "Invalid."; fi ;;
    10) read -p "Domain: " domain
       if [[ -n "$domain" ]]; then echo "$domain: $(status_domain $domain)"; else echo "Invalid."; fi ;;
    11) enable_dns_block ;;
    12) disable_dns_block ;;
    13) echo "Enemy DNS: $(status_dns)" ;;
    14) enable_tech_block ;;
    15) disable_tech_block ;;
    16) echo "Tech Companies: $(status_tech)" ;;
    17) total_lockdown ;;
    18) read -p "Save rules? (y/n): " save
       if [ "$save" == "y" ]; then iptables-save > /etc/iptables.rules; echo "Saved."; fi
       exit 0 ;;
    *) echo "Invalid." ;;
  esac
done
