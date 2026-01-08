#!/bin/bash
set -euo pipefail # Strict mode for error handling
if [ "$(id -u)" != "0" ]; then
   echo "Run as root." 1>&2
   exit 1
fi
# Install dependencies
function install_dependencies() {
  apt update -y || { echo "apt update failed."; exit 1; }
  apt install -y nftables wget netfilter-persistent dnsmasq fail2ban suricata curl jq tor snort || { echo "Installation failed."; exit 1; }
}
install_dependencies
# Country names mapping
declare -A country_names
country_names=( [cn]="China" [ru]="Russia" [ir]="Iran" [kp]="North Korea" [by]="Belarus" [sy]="Syria" [ve]="Venezuela" [cu]="Cuba" [pk]="Pakistan" [kh]="Cambodia" [mm]="Myanmar" [ni]="Nicaragua" [er]="Eritrea" [ml]="Mali" [cf]="Central African Republic" [bf]="Burkina Faso" [ne]="Niger" [gl]="Greenland"
[al]="Albania" [be]="Belgium" [bg]="Bulgaria" [ca]="Canada" [hr]="Croatia" [cz]="Czech Republic" [dk]="Denmark" [ee]="Estonia" [fi]="Finland" [fr]="France" [de]="Germany" [gr]="Greece" [hu]="Hungary" [is]="Iceland" [it]="Italy" [lv]="Latvia" [lt]="Lithuania" [lu]="Luxembourg" [me]="Montenegro" [nl]="Netherlands" [mk]="North Macedonia" [no]="Norway" [pl]="Poland" [pt]="Portugal" [ro]="Romania" [sk]="Slovakia" [si]="Slovenia" [es]="Spain" [se]="Sweden" [tr]="Turkey" [gb]="United Kingdom" [us]="United States" [in]="India" [br]="Brazil" [za]="South Africa" [ua]="Ukraine" )
countries=(cn ru ir kp by sy ve cu pk kh mm ni er ml cf bf ne gl al be bg ca hr cz dk ee fi fr de gr hu is it lv lt lu me nl mk no pl pt ro sk si es se tr gb us in br za ua)
# Predefined groups for blocking
declare -A groups
groups[enemies]="ru cn ir ve kp gl"
groups[allies]="by sy cu pk kh mm ni er ml cf bf ne"
groups[all_enemies]="ru cn ir ve kp gl by sy cu pk kh mm ni er ml cf bf ne"
groups[nato]="al be bg ca hr cz dk ee fi fr de gr hu is it lv lt lu me nl mk no pl pt ro sk si es se tr gb us"
groups[greenland]="gl"
groups[india]="in"
groups[brics]="br ru in cn za"
# Enemy DNS IPs for blocking
dns_ips=("202.46.34.74" "202.46.34.76" "114.114.115.119" "114.114.114.114" "114.114.115.115" "202.46.33.250" "103.251.105.188" "1.12.13.53" "121.4.4.41" "103.144.53.209" "223.6.6.199" "223.5.5.17" "103.144.53.104" "120.53.53.84" "223.6.6.198" "223.5.5.219" "140.210.69.173" "223.6.6.141" "223.6.6.56" "103.251.106.105" "103.144.52.233" "223.6.6.72" "120.53.53.116" "223.5.5.51" "223.6.6.46" "223.5.5.190" "120.53.53.183" "223.6.6.169" "223.6.6.195" "103.144.52.214" "223.5.5.224" "173.82.141.168" "223.5.5.111" "223.6.6.6" "120.53.53.54" "223.6.6.17" "120.53.53.198" "202.46.34.75" "103.144.52.240" "223.6.6.204" "223.5.5.228" "223.6.6.127" "223.5.5.148" "223.6.6.133" "121.4.4.246" "223.5.5.187" "223.5.5.123" "223.5.5.82" "223.6.6.139" "223.5.5.79"
"77.88.8.1" "77.88.8.3" "77.88.8.88" "94.158.96.2" "92.223.65.71" "194.67.109.176" "195.112.96.34" "195.208.5.1" "89.250.221.106" "93.157.172.153" "5.44.54.106" "94.180.111.233" "178.161.150.190" "217.150.35.129" "185.51.61.101" "37.193.226.251" "46.73.33.253" "80.82.55.71" "212.46.255.78" "62.176.12.111" "193.242.151.45" "77.233.5.68" "195.191.182.103" "80.245.115.97" "46.229.136.244" "84.53.247.204" "46.28.130.214" "91.223.120.25" "81.211.101.154" "46.254.217.54" "62.76.161.12" "62.213.14.166" "94.140.208.226" "86.62.120.68" "195.209.131.19" "85.172.19.214" "185.175.119.206" "109.195.194.79" "91.144.139.3" "185.123.194.28" "95.143.220.5" "79.142.95.90" "31.15.89.51" "46.146.209.132"
"185.231.182.126" "46.224.1.42" "185.187.84.15" "37.156.145.229" "185.97.117.187" "185.113.59.253" "80.191.40.41" "2.189.44.44" "2.188.21.131" "2.188.21.132" "81.91.144.116" "2.188.21.130" "92.119.56.162"
"213.184.224.254" "178.124.158.2" "178.124.152.74" "93.125.113.35" "46.175.171.234" "185.183.120.21" "93.84.101.216" "178.124.159.30" "86.57.182.174" "91.149.187.184" "212.98.162.203" "178.124.177.210" "86.57.139.244" "86.57.176.116" "194.158.209.165" "128.65.52.254" "195.222.86.106" "93.84.111.88" "178.124.160.248" "185.152.136.106" "195.50.2.26" "86.57.155.140" "46.216.167.108" "86.57.198.85" "194.158.219.140" "46.216.167.100" "178.124.204.179" "86.57.159.5" "93.125.21.75" "128.65.50.195" "37.17.61.236" "91.149.191.93" "86.57.235.57" "82.209.196.43" "82.209.223.188" "93.125.100.210" "82.209.232.162" "82.209.222.156" "86.57.135.118" "87.252.252.247" "87.252.224.22" "86.57.165.148" "86.57.209.91" "185.183.123.14" "93.84.120.167" "178.124.217.181" "178.124.162.168" "86.57.199.207" "86.57.245.133" "86.57.131.58"
"91.144.22.198" "82.137.245.41" "82.137.250.45" "95.159.63.33" "178.253.103.88"
"138.122.5.218" "186.167.33.244" "186.24.50.164" "190.120.250.165" "190.120.250.221" "45.230.168.17" "190.216.229.111" "190.216.229.245" "190.216.230.18" "190.216.237.1" "190.216.237.18" "190.216.238.105" "190.216.250.222" "190.216.250.42" "190.216.254.200" "190.217.13.229" "190.217.14.105" "190.217.14.213" "190.217.14.25" "190.217.14.45" "190.217.14.65" "190.217.4.78" "190.217.5.132" "190.217.5.161" "190.217.6.145" "190.217.8.247" "190.217.8.254" "200.41.114.91" "201.234.235.90" "204.199.248.34" "45.185.17.33" "200.35.86.182" "190.200.178.197" "186.166.142.196" "190.77.28.245" "190.77.7.86" "190.74.108.6" "201.242.191.158" "200.11.138.11" "201.249.153.60" "186.24.14.114" "190.78.57.226" "190.75.35.240" "45.187.94.147" "45.186.201.40" "190.75.143.216" "190.73.28.245" "190.203.165.255" "201.248.203.64" "200.35.77.10"
"181.225.255.203" "152.206.80.254" "152.206.201.49" "190.15.159.183" "152.206.201.77" "152.206.201.169" "152.206.139.42" "190.15.158.251"
"182.176.149.66" "125.209.66.170" "59.103.243.83" "59.103.138.123" "180.178.189.118" "110.38.74.58" "110.38.57.243" "118.103.236.13" "221.120.192.202" "110.36.213.38" "58.27.244.146" "180.178.189.68" "210.56.8.8" "103.168.40.14" "223.29.230.190" "103.189.127.102" "125.209.74.126" "203.135.5.90" "103.152.117.145" "103.166.102.21" "203.175.76.129" "202.142.189.98" "202.163.76.123" "43.246.225.217" "103.151.46.13" "121.52.157.202" "61.5.134.35" "58.27.249.124" "221.120.237.70" "103.152.100.142" "103.153.15.79" "115.186.46.233" "202.69.60.254" "202.83.175.188" "103.62.235.10" "103.154.64.142" "116.213.34.101" "137.59.192.182" "203.223.169.178" "111.68.108.215" "202.163.76.75" "103.189.127.107" "202.166.160.75" "123.108.93.129" "103.138.51.141" "103.83.89.154" "202.63.198.49" "119.156.31.221" "103.189.127.109" "103.115.199.129"
"36.37.160.242" "96.9.69.164" "175.100.18.45" "49.156.42.210" "36.37.230.149" "27.109.116.28" "103.248.42.72" "103.16.63.166" "103.242.58.166" "103.242.58.167" "202.62.58.23" "36.37.181.118" "202.62.58.27" "43.230.192.98" "43.230.195.99" "202.178.113.40" "116.212.140.211" "116.212.139.221" "96.9.88.2" "116.212.143.233" "111.118.147.236" "202.8.73.210" "124.248.191.83" "202.7.52.100" "43.230.195.197" "116.212.151.101" "45.133.168.112" "202.62.59.234" "103.16.61.114" "45.250.237.142" "203.189.130.131" "96.9.88.185"
"103.116.12.199" "103.203.133.66" "103.85.107.99" "103.85.107.101" "103.121.228.1" "103.154.241.252" "136.228.160.250" "65.18.114.254" "74.50.211.90" "210.14.104.230" "203.81.95.70" "103.121.228.5" "103.80.38.1" "103.213.30.95" "103.115.23.44" "103.25.79.178" "103.85.104.41" "121.54.164.130" "103.80.36.185" "65.18.112.106" "121.54.164.26" "202.165.95.74" "202.165.94.82" "203.81.66.105" "185.133.214.154" "185.205.140.22" "202.165.94.42" "37.111.52.18" "202.191.103.142" "180.235.117.54" "136.228.168.10" "202.191.109.18" "103.129.77.238"
"209.124.101.114" "209.124.106.181" "190.106.2.103" "161.0.62.217" "200.62.96.39" "186.1.41.26" "190.212.138.62" "165.98.68.126" "186.1.29.134" "190.106.27.204" "186.1.5.133" "191.102.49.167" "186.1.35.130" "190.106.12.226" "186.1.3.120" "191.98.231.158" "186.1.47.215" "209.124.106.178" "190.106.16.210" "45.170.225.42" "200.62.105.186" "161.0.61.117" "186.1.43.98" "186.1.41.92" "190.212.182.165" "186.1.45.124" "186.1.32.106" "186.1.35.243" "186.1.16.180" "186.1.44.141" "186.1.38.84" "186.1.5.66" "190.124.39.34" "190.106.16.58" "190.106.9.154" "190.106.26.158" "191.98.230.2" "161.0.36.214" "190.106.13.102" "191.98.238.202" "191.98.236.242" "186.1.14.164"
"154.118.190.94" "196.200.48.40" "217.64.99.25"
"206.82.130.195" "102.36.165.254" "41.216.155.193" "102.222.56.2" "41.216.159.6" "41.138.101.251" "165.16.213.111" "196.28.244.3" "102.222.123.60" "41.216.154.11" "160.226.184.252" "41.216.155.245")
# Enemy DNS IPv6 IPs for blocking
dns_ipv6_ips=("2400:3200::1" "2400:3200:baba::1" "2400:da00::6666" "2a02:6b8::feed:0ff" "2a02:6b8:0:1::feed:0ff" "2001:6d0:6d0::2001" "2001:6d0:d6::2001" "2a0c:a9c7:8::1" "2a0c:a9c7:9::1")
# Military domains
military_domains=("rosoboronexport.ru" "uacrussia.ru" "almaz-antey.ru" "norinco.com" "avic.com" "casc.cn" "iaio.ir" "dio.ir" "cavim.com.ve")
# Domain groups for easy management
declare -A domain_groups
domain_groups[tech]="google.com youtube.com facebook.com instagram.com amazon.com microsoft.com apple.com netflix.com x.com tiktok.com whatsapp.com linkedin.com yahoo.com baidu.com yandex.ru alibaba.com"
domain_groups[enemy_social]="vk.com ok.ru rutube.ru mail.ru weibo.com qq.com weixin.qq.com douyin.com bilibili.com aparat.ir cloob.com bale.ai soroush-app.ir"
domain_groups[enemy_media]="rt.com sputniknews.com tass.ru ria.ru cgtn.com globaltimes.cn xinhuanet.com chinadaily.com.cn presstv.ir tasnimnews.com farsi.irib.ir kcna.kp rodong.rep.kp telesurtv.net vtv.gob.ve"
domain_groups[military]="rosoboronexport.ru uacrussia.ru almaz-antey.ru norinco.com avic.com casc.cn iaio.ir dio.ir cavim.com.ve"
domain_groups[foreign_tech]="tencent.com huawei.com bytedance.com mi.com jd.com meituan.com pinduoduo.com didiglobal.com smics.com sensetime.com yandex.ru kaspersky.com 1c.ru wildberries.ru ozon.ru digikala.com snapp.ir cafebazaar.ir epam.com iba.by wargaming.com systemsltd.com netsoltech.com confiz.com trgworld.com ibex.co tkxel.com 10pearls.com ezecom.com.kh sinet.com.kh frontiir.com wavemoney.com.mm oway.com.mm infosys.com tcs.com wipro.com hcltech.com techmahindra.com zoho.com paytm.com flipkart.com ola.com byjus.com phonepe.com swiggy.com makemytrip.com freshworks.com postman.com"
# Enemy TLDs
enemy_tlds=("ru" "cn" "ir" "kp" "by" "sy" "ve" "cu" "pk" "kh" "mm" "ni" "er" "ml" "cf" "bf" "ne")
DNSMASQ_CONF="/etc/dnsmasq.d/blocked-domains.conf"
HOSTS_FILE="/etc/hosts"
BLOCK_MARKER="# AntiCrack Domain Block"
BLOCKED_DOMAINS_FILE="/tmp/anticrack_domains.txt"
THREAT_LIST_URL="https://feodotracker.abuse.ch/downloads/ipblocklist.txt"
SPAMHAUS_DROP_URL="https://www.spamhaus.org/drop/drop.txt"
TOR_EXIT_URL="https://www.dan.me.uk/torlist/?exit"
VPN_LIST_URL="https://raw.githubusercontent.com/X4BNet/lists_vpn/main/ipv4.txt"
NFT_BACKUP="/etc/nftables.backup.conf"
# Safety: Backup rules before changes
function backup_rules() {
  nft list ruleset > "$NFT_BACKUP"
  echo "Rules backed up to $NFT_BACKUP."
}
# Check command execution
function check_command() {
  "$@" || { echo "Command failed: $*"; exit 1; }
}
# Initialize nft tables and chains if not exist
function init_nft() {
  nft list table ip filter > /dev/null 2>&1 || nft 'add table ip filter'
  nft list chain ip filter input > /dev/null 2>&1 || nft 'add chain ip filter input { type filter hook input priority 0; policy accept; }'
  nft list chain ip filter output > /dev/null 2>&1 || nft 'add chain ip filter output { type filter hook output priority 0; policy accept; }'
  nft list table ip6 filter > /dev/null 2>&1 || nft 'add table ip6 filter'
  nft list chain ip6 filter input > /dev/null 2>&1 || nft 'add chain ip6 filter input { type filter hook input priority 0; policy accept; }'
  nft list chain ip6 filter output > /dev/null 2>&1 || nft 'add chain ip6 filter output { type filter hook output priority 0; policy accept; }'
  nft list table bridge filter > /dev/null 2>&1 || nft 'add table bridge filter'
  nft list chain bridge filter input > /dev/null 2>&1 || nft 'add chain bridge filter input { type filter hook input priority -200; policy accept; }' # For ebtables-like
  nft list chain bridge filter broute > /dev/null 2>&1 || nft 'add chain bridge filter broute { type filter hook prerouting priority -300; policy accept; }' # For BROUTING
  nft add set ip filter white-ips { type ipv4_addr\; flags interval\; } 2>/dev/null
  nft add set ip6 filter white-ips6 { type ipv6_addr\; flags interval\; } 2>/dev/null
  nft add set ip filter custom-block { type ipv4_addr\; flags interval\; } 2>/dev/null
  nft add set ip6 filter custom-block6 { type ipv6_addr\; flags interval\; } 2>/dev/null
  nft add rule ip filter input ip saddr @white-ips accept 2>/dev/null
  nft add rule ip filter output ip daddr @white-ips accept 2>/dev/null
  nft add rule ip6 filter input ip6 saddr @white-ips6 accept 2>/dev/null
  nft add rule ip6 filter output ip6 daddr @white-ips6 accept 2>/dev/null
  nft add rule ip filter input ip saddr @custom-block drop 2>/dev/null
  nft add rule ip filter output ip daddr @custom-block drop 2>/dev/null
  nft add rule ip6 filter input ip6 saddr @custom-block6 drop 2>/dev/null
  nft add rule ip6 filter output ip6 daddr @custom-block6 drop 2>/dev/null
}
init_nft
# Country block status
function status_country() {
  nft list set ip filter "block-$1" >/dev/null 2>&1 && echo "Enabled" || echo "Disabled"
}
# Enable country block
function enable_country() {
  local c=$1
  backup_rules
  read -p "Confirm enable ${country_names[$c]}? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  if [ "$(status_country $c)" == "Enabled" ]; then
    echo "${country_names[$c]} already enabled."
    return
  fi
  check_command wget -q "https://www.ipdeny.com/ipblocks/data/aggregated/${c}-aggregated.zone" -O "/tmp/${c}.zone"
  check_command wget -q "https://www.ipdeny.com/ipv6/ipaddresses/aggregated/${c}-aggregated.zone" -O "/tmp/${c}-v6.zone"
  nft add set ip filter "block-$c" { type ipv4_addr\; flags interval\; } 2>/dev/null
  nft add set ip6 filter "block-${c}-v6" { type ipv6_addr\; flags interval\; } 2>/dev/null
  while read -r ip; do
    [ -n "$ip" ] && nft add element ip filter "block-$c" { "$ip" }
  done < "/tmp/${c}.zone"
  while read -r ip; do
    [ -n "$ip" ] && nft add element ip6 filter "block-${c}-v6" { "$ip" }
  done < "/tmp/${c}-v6.zone"
  rm -f "/tmp/${c}.zone" "/tmp/${c}-v6.zone"
  nft add rule ip filter input ip saddr @"block-$c" drop 2>/dev/null
  nft add rule ip filter output ip daddr @"block-$c" drop 2>/dev/null
  nft add rule ip6 filter input ip6 saddr @"block-${c}-v6" drop 2>/dev/null
  nft add rule ip6 filter output ip6 daddr @"block-${c}-v6" drop 2>/dev/null
  echo "${country_names[$c]} enabled (IPv4/IPv6)."
}
# Disable country block
function disable_country() {
  local c=$1
  backup_rules
  read -p "Confirm disable ${country_names[$c]}? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  if [ "$(status_country $c)" == "Disabled" ]; then
    echo "${country_names[$c]} already disabled."
    return
  fi
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep @"block-$c" | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip filter output handle $(nft -a list chain ip filter output | grep @"block-$c" | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip6 filter input handle $(nft -a list chain ip6 filter input | grep @"block-${c}-v6" | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip6 filter output handle $(nft -a list chain ip6 filter output | grep @"block-${c}-v6" | awk '{print $NF}') 2>/dev/null || true
  nft delete set ip filter "block-$c" 2>/dev/null || true
  nft delete set ip6 filter "block-${c}-v6" 2>/dev/null || true
  echo "${country_names[$c]} disabled."
}
# Enable group of countries
function enable_group() {
  local g=$1
  for c in ${groups[$g]}; do
    enable_country $c
  done
  echo "$g group enabled."
}
# Disable group of countries
function disable_group() {
  local g=$1
  for c in ${groups[$g]}; do
    disable_country $c
  done
  echo "$g group disabled."
}
# Create custom group
function create_custom_group() {
  read -p "Custom group name: " group
  if [[ -n "${groups[$group]}" ]]; then
    echo "Group exists."
    return
  fi
  echo "Enter countries in format 'Country: code, Country: code' (e.g., Russia: ru, China: cn)"
  read -p "Countries: " input
  codes=$(echo "$input" | sed 's/[^:]*: \([a-z][a-z]\),*/\1 /g') || { echo "Invalid input."; return; }
  groups[$group]="$codes"
  echo "Custom group $group created with codes: $codes"
}
# DNS block status
function status_dns() {
  nft list set ip filter block-dns >/dev/null 2>&1 && echo "Enabled" || echo "Disabled"
}
# Enable DNS blocking
function enable_dns_block() {
  if [ "$(status_dns)" == "Enabled" ]; then
    echo "DNS block already enabled."
    return
  fi
  nft add set ip filter block-dns { type ipv4_addr\; } 2>/dev/null
  for ip in "${dns_ips[@]}"; do
    nft add element ip filter block-dns { "$ip" } 2>/dev/null
  done
  nft add set ip6 filter block-dns6 { type ipv6_addr\; } 2>/dev/null
  for ip in "${dns_ipv6_ips[@]}"; do
    nft add element ip6 filter block-dns6 { "$ip" } 2>/dev/null
  done
  nft add rule ip filter input ip saddr @block-dns drop 2>/dev/null
  nft add rule ip filter output ip daddr @block-dns drop 2>/dev/null
  nft add rule ip6 filter input ip6 saddr @block-dns6 drop 2>/dev/null
  nft add rule ip6 filter output ip6 daddr @block-dns6 drop 2>/dev/null
  echo "Enemy DNS blocked (IPv4/IPv6)."
}
# Disable DNS blocking
function disable_dns_block() {
  if [ "$(status_dns)" == "Disabled" ]; then
    echo "DNS block already disabled."
    return
  fi
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep @block-dns | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip filter output handle $(nft -a list chain ip filter output | grep @block-dns | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip6 filter input handle $(nft -a list chain ip6 filter input | grep @block-dns6 | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip6 filter output handle $(nft -a list chain ip6 filter output | grep @block-dns6 | awk '{print $NF}') 2>/dev/null || true
  nft delete set ip filter block-dns 2>/dev/null || true
  nft delete set ip6 filter block-dns6 2>/dev/null || true
  echo "Enemy DNS unblocked."
}
# Enable domain group blocking
function enable_domain_group() {
  local g=$1
  for d in ${domain_groups[$g]}; do
    block_domain "$d"
  done
  echo "$g domains blocked."
}
# Disable domain group blocking
function disable_domain_group() {
  local g=$1
  for d in ${domain_groups[$g]}; do
    unblock_domain "$d"
  done
  echo "$g domains unblocked."
}
# Status of domain group
function status_domain_group() {
  local g=$1
  local blocked=0
  local total=0
  for d in ${domain_groups[$g]}; do
    ((total++))
    [ "$(status_domain $d)" == "Blocked" ] && ((blocked++))
  done
  if [ $blocked -eq $total ]; then
    echo "Enabled"
  elif [ $blocked -eq 0 ]; then
    echo "Disabled"
  else
    echo "Partial ($blocked/$total)"
  fi
}
# TLD block functions
function block_tld() {
  local tld=$1
  backup_rules
  read -p "Confirm block .${tld}? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  if grep -q "/\.${tld}\//" "$DNSMASQ_CONF"; then
    echo ".${tld} already blocked."
    return
  fi
  echo "address=/.${tld}/0.0.0.0" >> "$DNSMASQ_CONF"
  systemctl restart dnsmasq
  echo ".${tld} blocked."
}
function unblock_tld() {
  local tld=$1
  backup_rules
  read -p "Confirm unblock .${tld}? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  sed -i "/\/\.${tld}\//d" "$DNSMASQ_CONF"
  systemctl restart dnsmasq
  echo ".${tld} unblocked."
}
function enable_tld_group() {
  for tld in "${enemy_tlds[@]}"; do
    block_tld "$tld"
  done
  echo "Enemy TLDs blocked."
}
function disable_tld_group() {
  for tld in "${enemy_tlds[@]}"; do
    unblock_tld "$tld"
  done
  echo "Enemy TLDs unblocked."
}
function status_tld_group() {
  local blocked=0
  local total=${#enemy_tlds[@]}
  for tld in "${enemy_tlds[@]}"; do
    grep -q "/\.${tld}\//" "$DNSMASQ_CONF" && ((blocked++))
  done
  if [ $blocked -eq $total ]; then
    echo "Enabled"
  elif [ $blocked -eq 0 ]; then
    echo "Disabled"
  else
    echo "Partial ($blocked/$total)"
  fi
}
# Total lockdown
function total_lockdown() {
  backup_rules
  read -p "Confirm total lockdown? This may disrupt connectivity (y/n): " confirm
  [ "$confirm" != "y" ] && return
  enable_group all_enemies
  enable_dns_block
  enable_domain_group tech
  enable_domain_group enemy_social
  enable_domain_group enemy_media
  enable_domain_group military
  enable_domain_group foreign_tech
  enable_tld_group
  enable_fail2ban
  enable_suricata
  enable_snort
  enable_tor_block
  enable_vpn_block
  update_threat_lists
  enable_rate_limiting
  enable_bridge_block
  echo "Total lockdown enabled - all enemy blocks, fail2ban, IDS, TOR/VPN block, threat updates, rate limiting, bridge block."
}
# List status of all components
function list_status() {
  echo "Countries:"
  for c in "${countries[@]}"; do
    echo "${country_names[$c]} ($c): $(status_country $c) - Blocks IP traffic."
  done
  echo "Enemy DNS: $(status_dns) - Blocks enemy DNS."
  echo "Tech: $(status_domain_group tech) - Blocks tech domains."
  echo "Enemy Social: $(status_domain_group enemy_social) - Blocks social."
  echo "Enemy Media: $(status_domain_group enemy_media) - Blocks media."
  echo "Military: $(status_domain_group military) - Blocks military domains."
  echo "Foreign Tech: $(status_domain_group foreign_tech) - Blocks foreign tech including Indian."
  echo "Enemy TLDs: $(status_tld_group) - Blocks enemy TLDs."
  echo "Fail2Ban: $(systemctl is-active fail2ban) - Intrusion prevention."
  echo "Suricata: $(systemctl is-active suricata) - IDS."
  echo "Snort: $(systemctl is-active snort) - IDS."
  echo "TOR Block: $(nft list set ip filter block-tor >/dev/null 2>&1 && echo Enabled || echo Disabled) - Blocks TOR exits."
  echo "VPN Block: $(nft list set ip filter block-vpn >/dev/null 2>&1 && echo Enabled || echo Disabled) - Blocks VPNs."
  echo "Rate Limiting: $(nft list chain ip filter input | grep 'limit' >/dev/null && echo Enabled || echo Disabled) - Limits connections."
  echo "Bridge Block: $(nft list chain bridge filter broute >/dev/null 2>&1 && echo Enabled || echo Disabled) - Ebtables integration for bridge filtering."
  echo "Custom Block: $(nft list set ip filter custom-block >/dev/null 2>&1 && echo Enabled || echo Disabled) - Custom IP blocks."
}
# Domain status
function status_domain() {
  local d=$1
  grep -q "^0.0.0.0 $d $BLOCK_MARKER" "$HOSTS_FILE" && echo "Blocked (hosts)" || (grep -q "/.$d/" "$DNSMASQ_CONF" && echo "Blocked (dnsmasq)" || echo "Not blocked")
}
# Block domain
function block_domain() {
  local d=$1
  backup_rules
  read -p "Confirm block $d? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  if [[ "$d" == *'*'* ]]; then
    d=${d/\*/} # Remove * for dnsmasq format
    if grep -q "/.$d/" "$DNSMASQ_CONF"; then
      echo "$d already blocked."
      return
    fi
    echo "address=/.$d/0.0.0.0" >> "$DNSMASQ_CONF" || { echo "Failed to write to dnsmasq."; exit 1; }
    systemctl restart dnsmasq || { echo "dnsmasq restart failed."; exit 1; }
    echo "$d wildcard blocked via dnsmasq."
  else
    if [ "$(status_domain $d)" == "Blocked (hosts)" ]; then
      echo "$d already blocked."
      return
    fi
    echo "0.0.0.0 $d $BLOCK_MARKER" >> "$HOSTS_FILE" || { echo "Failed to write to hosts."; exit 1; }
    echo "0.0.0.0 www.$d $BLOCK_MARKER" >> "$HOSTS_FILE" || { echo "Failed to write to hosts."; exit 1; }
    echo "$d blocked (with www.)."
  fi
}
# Unblock domain
function unblock_domain() {
  local d=$1
  backup_rules
  read -p "Confirm unblock $d? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  if [[ "$d" == *'*'* ]]; then
    d=${d/\*/}
    sed -i "/\/.$d\//d" "$DNSMASQ_CONF" || { echo "Failed to edit dnsmasq."; exit 1; }
    systemctl restart dnsmasq || { echo "dnsmasq restart failed."; exit 1; }
    echo "$d wildcard unblocked."
  else
    if [ "$(status_domain $d)" == "Not blocked" ]; then
      echo "$d not blocked."
      return
    fi
    sed -i "/^0.0.0.0 $d $BLOCK_MARKER/d" "$HOSTS_FILE" || { echo "Failed to edit hosts."; exit 1; }
    sed -i "/^0.0.0.0 www.$d $BLOCK_MARKER/d" "$HOSTS_FILE" || { echo "Failed to edit hosts."; exit 1; }
    echo "$d unblocked."
  fi
}
# List blocked domains
function list_blocked_domains() {
  grep "$BLOCK_MARKER" "$HOSTS_FILE" | awk '{print $2 " - Blocked (hosts)."}' > "$BLOCKED_DOMAINS_FILE" || { echo "Failed to list domains."; exit 1; }
  grep "address=" "$DNSMASQ_CONF" | awk -F'/' '{print "*." $2 " - Blocked (dnsmasq)."}' >> "$BLOCKED_DOMAINS_FILE"
  if [ -s "$BLOCKED_DOMAINS_FILE" ]; then
    cat "$BLOCKED_DOMAINS_FILE"
  else
    echo "No domains blocked."
  fi
  rm -f "$BLOCKED_DOMAINS_FILE"
}
# Enable logging
function enable_logging() {
  backup_rules
  read -p "Confirm enable logging? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  nft add rule ip filter input log prefix "AntiCrack DROP: " 2>/dev/null
  nft add rule ip filter output log prefix "AntiCrack DROP: " 2>/dev/null
  nft add rule ip6 filter input log prefix "AntiCrack DROP: " 2>/dev/null
  nft add rule ip6 filter output log prefix "AntiCrack DROP: " 2>/dev/null
  echo "Firewall logging enabled."
}
# Disable logging
function disable_logging() {
  backup_rules
  read -p "Confirm disable logging? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep 'log prefix "AntiCrack DROP: "' | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip filter output handle $(nft -a list chain ip filter output | grep 'log prefix "AntiCrack DROP: "' | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip6 filter input handle $(nft -a list chain ip6 filter input | grep 'log prefix "AntiCrack DROP: "' | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip6 filter output handle $(nft -a list chain ip6 filter output | grep 'log prefix "AntiCrack DROP: "' | awk '{print $NF}') 2>/dev/null || true
  echo "Firewall logging disabled."
}
# Flush all rules
function flush_rules() {
  backup_rules
  read -p "Confirm flush all rules? This will remove all firewall rules (y/n): " confirm
  [ "$confirm" != "y" ] && return
  nft flush table ip filter 2>/dev/null
  nft delete table ip filter 2>/dev/null
  nft flush table ip6 filter 2>/dev/null
  nft delete table ip6 filter 2>/dev/null
  nft flush table bridge filter 2>/dev/null
  nft delete table bridge filter 2>/dev/null
  init_nft
  echo "All rules flushed - network down for reconfiguration."
}
# Restore saved rules
function restore_rules() {
  read -p "Confirm restore from backup? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  if [ -f "$NFT_BACKUP" ]; then
    nft -f "$NFT_BACKUP"
    echo "Rules restored - network up."
  else
    echo "No backup found."
  fi
}
# Enable Fail2Ban
function enable_fail2ban() {
  backup_rules
  read -p "Confirm enable Fail2Ban? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  cat << EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
[sshd]
enabled = true
EOF
  systemctl enable fail2ban
  systemctl restart fail2ban
  echo "Fail2Ban enabled for SSH."
}
# Disable Fail2Ban
function disable_fail2ban() {
  backup_rules
  read -p "Confirm disable Fail2Ban? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  systemctl stop fail2ban
  systemctl disable fail2ban
  echo "Fail2Ban disabled."
}
# Enable Suricata IDS
function enable_suricata() {
  backup_rules
  read -p "Confirm enable Suricata? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  suricata-update
  systemctl enable suricata
  systemctl start suricata
  echo "Suricata IDS enabled."
}
# Disable Suricata
function disable_suricata() {
  backup_rules
  read -p "Confirm disable Suricata? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  systemctl stop suricata
  systemctl disable suricata
  echo "Suricata disabled."
}
# Enable Snort IDS
function enable_snort() {
  backup_rules
  read -p "Confirm enable Snort? Configure /etc/snort/snort.conf for interface (y/n): " confirm
  [ "$confirm" != "y" ] && return
  systemctl enable snort
  systemctl start snort
  echo "Snort IDS enabled."
}
# Disable Snort
function disable_snort() {
  backup_rules
  read -p "Confirm disable Snort? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  systemctl stop snort
  systemctl disable snort
  echo "Snort disabled."
}
# Update threat lists from malware sources
function update_threat_lists() {
  backup_rules
  read -p "Confirm update threat lists? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  wget -q "$THREAT_LIST_URL" -O /tmp/threat-ips.txt
  wget -q "$SPAMHAUS_DROP_URL" -O /tmp/spamhaus.txt
  nft add set ip filter threat-ips { type ipv4_addr\; flags interval\; } 2>/dev/null || nft flush set ip filter threat-ips
  while read -r ip; do
    [ -n "$ip" ] && [[ ! $ip =~ ^# ]] && nft add element ip filter threat-ips { "$ip" }
  done < /tmp/threat-ips.txt
  sed '/^;/d' /tmp/spamhaus.txt | awk -F' ; ' '{print $1}' | while read -r ip; do
    [ -n "$ip" ] && nft add element ip filter threat-ips { "$ip" }
  done
  nft add rule ip filter input ip saddr @threat-ips drop 2>/dev/null
  nft add rule ip filter output ip daddr @threat-ips drop 2>/dev/null
  rm -f /tmp/threat-ips.txt /tmp/spamhaus.txt
  echo "Threat lists updated."
}
# Enable TOR blocking
function enable_tor_block() {
  backup_rules
  read -p "Confirm enable TOR block? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  curl -s "$TOR_EXIT_URL" -o /tmp/tor-exits.txt
  nft add set ip filter block-tor { type ipv4_addr\; } 2>/dev/null || nft flush set ip filter block-tor
  while read -r ip; do
    nft add element ip filter block-tor { "$ip" }
  done < /tmp/tor-exits.txt
  nft add rule ip filter input ip saddr @block-tor drop 2>/dev/null
  nft add rule ip filter output ip daddr @block-tor drop 2>/dev/null
  echo "TOR exits blocked."
}
# Disable TOR blocking
function disable_tor_block() {
  backup_rules
  read -p "Confirm disable TOR block? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep @block-tor | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip filter output handle $(nft -a list chain ip filter output | grep @block-tor | awk '{print $NF}') 2>/dev/null || true
  nft delete set ip filter block-tor 2>/dev/null || true
  echo "TOR block disabled."
}
# Enable VPN blocking
function enable_vpn_block() {
  backup_rules
  read -p "Confirm enable VPN block? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  wget -q "$VPN_LIST_URL" -O /tmp/vpn-ips.txt
  nft add set ip filter block-vpn { type ipv4_addr\; flags interval\; } 2>/dev/null || nft flush set ip filter block-vpn
  while read -r ip; do
    [ -n "$ip" ] && [[ ! $ip =~ ^# ]] && nft add element ip filter block-vpn { "$ip" }
  done < /tmp/vpn-ips.txt
  nft add rule ip filter input ip saddr @block-vpn drop 2>/dev/null
  nft add rule ip filter output ip daddr @block-vpn drop 2>/dev/null
  echo "VPNs blocked."
}
# Disable VPN blocking
function disable_vpn_block() {
  backup_rules
  read -p "Confirm disable VPN block? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep @block-vpn | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip filter output handle $(nft -a list chain ip filter output | grep @block-vpn | awk '{print $NF}') 2>/dev/null || true
  nft delete set ip filter block-vpn 2>/dev/null || true
  echo "VPN block disabled."
}
# Enable rate limiting for DDoS protection
function enable_rate_limiting() {
  backup_rules
  read -p "Confirm enable rate limiting? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  nft add rule ip filter input tcp dport 80 limit rate 25/minute burst 100 packets accept 2>/dev/null
  nft add rule ip filter input tcp dport 80 drop 2>/dev/null
  nft add rule ip filter input tcp dport 443 limit rate 25/minute burst 100 packets accept 2>/dev/null
  nft add rule ip filter input tcp dport 443 drop 2>/dev/null
  nft add rule ip filter input tcp flags syn limit rate 1/second burst 3 packets accept 2>/dev/null
  nft add rule ip filter input tcp flags syn drop 2>/dev/null
  echo "Rate limiting and SYN flood protection enabled."
}
# Disable rate limiting
function disable_rate_limiting() {
  backup_rules
  read -p "Confirm disable rate limiting? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep 'tcp dport 80 limit' | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep 'tcp dport 80 drop' | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep 'tcp dport 443 limit' | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep 'tcp dport 443 drop' | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep 'tcp flags syn limit' | awk '{print $NF}') 2>/dev/null || true
  nft delete rule ip filter input handle $(nft -a list chain ip filter input | grep 'tcp flags syn drop' | awk '{print $NF}') 2>/dev/null || true
  echo "Rate limiting disabled."
}
# Enable bridge block (ebtables integration)
function enable_bridge_block() {
  backup_rules
  read -p "Confirm enable bridge block (ebtables-like)? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  nft add rule bridge filter broute ether saddr != 00:00:00:00:00:00 meta broute set 1 drop 2>/dev/null # Example: Drop non-zero MAC in broute
  echo "Bridge block enabled (example rule; customize as needed)."
}
# Disable bridge block
function disable_bridge_block() {
  backup_rules
  read -p "Confirm disable bridge block? (y/n): " confirm
  [ "$confirm" != "y" ] && return
  nft delete rule bridge filter broute handle $(nft -a list chain bridge filter broute | grep 'meta broute' | awk '{print $NF}') 2>/dev/null || true
  echo "Bridge block disabled."
}
# Custom IP block
function block_custom_ip() {
  read -p "IP/CIDR (IPv4 or IPv6): " ip
  if [[ $ip == *:* ]]; then
    nft add element ip6 filter custom-block6 { "$ip" }
  else
    nft add element ip filter custom-block { "$ip" }
  fi
  echo "Custom IP $ip blocked."
}
# Whitelisting
function add_white_ip() {
  read -p "IP/CIDR to whitelist (IPv4 or IPv6): " ip
  if [[ $ip == *:* ]]; then
    nft add element ip6 filter white-ips6 { "$ip" }
  else
    nft add element ip filter white-ips { "$ip" }
  fi
  echo "IP $ip whitelisted."
}
# Setup cron for auto updates
function setup_cron() {
  local script_path=$(realpath $0)
  crontab -l | { cat; echo "0 0 * * * $script_path update_threat_lists > /dev/null 2>&1"; } | crontab -
  echo "Cron setup for daily threat list updates."
}
# List available countries
function list_countries() {
  for c in "${!country_names[@]}"; do
    echo "${country_names[$c]}: $c"
  done
}
# Handle command line args for cron
if [ $# -gt 0 ]; then
  case $1 in
    update_threat_lists) update_threat_lists ;;
  esac
  exit 0
fi
echo "AntiCrack Global Blocker"
echo "Secures US internet by blocking enemies in WW3. Blocks IPs, domains, DNS for total lockdown."
echo "Warning: Root required. May break access. Backup configs. Use at own risk. IPv6 supported, logging available."
echo "Safety: All changes backup ruleset. Confirmations required for major actions."
echo "Available countries:"
list_countries
echo "Improved with nftables for efficiency (use flowtables for forwarding optimization - add 'flowtable { devices = [ \"eth0\", \"eth1\" ]; }' in nft.conf if needed), ebtables integration via bridge family, foreign tech including Indian, optimized structure, custom targeting, concise code, automatic persistence."
while true; do
  echo "1) List status - Shows all blocks."
  echo "2) Enable country - Block IP ranges (IPv4/IPv6)."
  echo "3) Disable country - Unblock."
  echo "4) Status of country - Check."
  echo "5) Enable group (enemies/allies/all_enemies/nato/greenland/india/brics/custom) - Block group IPs."
  echo "6) Disable group - Unblock group."
  echo "7) List blocked domains - Shows domains."
  echo "8) Block domain - Enter domain or *.domain for wildcard."
  echo "9) Unblock domain - Enter domain or *.domain."
  echo "10) Status of domain - Check domain."
  echo "11) Enable DNS block - Block enemy DNS IPv4/IPv6."
  echo "12) Disable DNS block - Unblock."
  echo "13) Status of DNS block - Check."
  echo "14) Enable domain group (tech/enemy_social/enemy_media/military/foreign_tech) - Block group domains."
  echo "15) Disable domain group - Unblock."
  echo "16) Status of domain group - Check."
  echo "17) Create custom group - Name, enter 'Country: code, ...'."
  echo "18) Enable logging - Log drops."
  echo "19) Disable logging - Stop logging."
  echo "20) Flush rules - Flush rules for reconfig."
  echo "21) Restore rules - Restore from backup."
  echo "22) Total lockdown - All enemy blocks + WW3 features."
  echo "23) Enable Fail2Ban - Intrusion prevention."
  echo "24) Disable Fail2Ban"
  echo "25) Enable Suricata IDS"
  echo "26) Disable Suricata"
  echo "27) Update threat lists - From malware feeds."
  echo "28) Enable TOR block"
  echo "29) Disable TOR block"
  echo "30) Enable VPN block"
  echo "31) Disable VPN block"
  echo "32) Enable rate limiting - For DDoS mitigation."
  echo "33) Disable rate limiting"
  echo "34) Enable Snort IDS"
  echo "35) Disable Snort"
  echo "36) Enable bridge block - Ebtables integration."
  echo "37) Disable bridge block"
  echo "38) Block custom IP - Add IP/CIDR to custom block."
  echo "39) Enable enemy TLD block - Block .ru, .cn etc."
  echo "40) Disable enemy TLD block"
  echo "41) Status of enemy TLD block"
  echo "42) Block TLD - Enter tld like ru"
  echo "43) Unblock TLD"
  echo "44) Add white IP - Whitelist IP/CIDR"
  echo "45) Setup cron - Daily threat update"
  echo "46) Exit"
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
    14) read -p "Domain group: " group
       if [[ -n "${domain_groups[$group]}" ]]; then enable_domain_group $group; else echo "Invalid."; fi ;;
    15) read -p "Domain group: " group
       if [[ -n "${domain_groups[$group]}" ]]; then disable_domain_group $group; else echo "Invalid."; fi ;;
    16) read -p "Domain group: " group
       if [[ -n "${domain_groups[$group]}" ]]; then echo "$group: $(status_domain_group $group)"; else echo "Invalid."; fi ;;
    17) create_custom_group ;;
    18) enable_logging ;;
    19) disable_logging ;;
    20) flush_rules ;;
    21) restore_rules ;;
    22) total_lockdown ;;
    23) enable_fail2ban ;;
    24) disable_fail2ban ;;
    25) enable_suricata ;;
    26) disable_suricata ;;
    27) update_threat_lists ;;
    28) enable_tor_block ;;
    29) disable_tor_block ;;
    30) enable_vpn_block ;;
    31) disable_vpn_block ;;
    32) enable_rate_limiting ;;
    33) disable_rate_limiting ;;
    34) enable_snort ;;
    35) disable_snort ;;
    36) enable_bridge_block ;;
    37) disable_bridge_block ;;
    38) block_custom_ip ;;
    39) enable_tld_group ;;
    40) disable_tld_group ;;
    41) echo "Enemy TLDs: $(status_tld_group)" ;;
    42) read -p "TLD: " tld
       if [[ -n "$tld" ]]; then block_tld $tld; else echo "Invalid."; fi ;;
    43) read -p "TLD: " tld
       if [[ -n "$tld" ]]; then unblock_tld $tld; else echo "Invalid."; fi ;;
    44) add_white_ip ;;
    45) setup_cron ;;
    46) read -p "Save rules? (y/n): " save
       if [ "$save" == "y" ]; then nft list ruleset > /etc/nftables.conf; echo "Saved to /etc/nftables.conf."; fi
       exit 0 ;;
    *) echo "Invalid." ;;
  esac
done
