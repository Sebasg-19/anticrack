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

function status() {
  local c=$1
  if ipset list "block-$c" >/dev/null 2>&1; then
    echo "Enabled"
  else
    echo "Disabled"
  fi
}

function enable_country() {
  local c=$1
  if [ "$(status $c)" == "Enabled" ]; then
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
  if [ "$(status $c)" == "Disabled" ]; then
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

function list_status() {
  for c in "${countries[@]}"; do
    echo "${country_names[$c]} ($c): $(status $c) - Blocks all IP traffic to/from ${country_names[$c]}, may disrupt services."
  done
}

echo "AntiCrack Global Blocker"
echo "For securing US internet by blocking enemy countries in WW3."
echo "Warning: Root required. Blocks entire countries - may break legit access. Backup iptables/hosts. Use at risk."
echo "Improved with ipset for efficiency."

while true; do
  echo "1) List status"
  echo "2) Enable country"
  echo "3) Disable country"
  echo "4) Status of country"
  echo "5) Enable group (enemies/allies/greenland)"
  echo "6) Disable group"
  echo "7) Exit"
  read -p "Choice: " choice
  case $choice in
    1) list_status ;;
    2) read -p "Country code: " code
       if [[ " ${countries[*]} " =~ " ${code} " ]]; then enable_country $code; else echo "Invalid."; fi ;;
    3) read -p "Country code: " code
       if [[ " ${countries[*]} " =~ " ${code} " ]]; then disable_country $code; else echo "Invalid."; fi ;;
    4) read -p "Country code: " code
       if [[ " ${countries[*]} " =~ " ${code} " ]]; then echo "${country_names[$code]}: $(status $code)"; else echo "Invalid."; fi ;;
    5) read -p "Group (enemies/allies/greenland): " group
       if [[ -n "${groups[$group]}" ]]; then enable_group $group; else echo "Invalid."; fi ;;
    6) read -p "Group: " group
       if [[ -n "${groups[$group]}" ]]; then disable_group $group; else echo "Invalid."; fi ;;
    7) read -p "Save rules? (y/n): " save
       if [ "$save" == "y" ]; then iptables-save > /etc/iptables.rules; echo "Saved."; fi
       exit 0 ;;
    *) echo "Invalid." ;;
  esac
done
