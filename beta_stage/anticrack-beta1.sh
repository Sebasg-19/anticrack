country_names[nsa]="NSA"
country_names[fbi]="FBI"
countries+=(nsa fbi)
groups[all_enemies]+=" nsa fbi"

# NSA/FBI IP ranges (add to blocking function, e.g., nftables drop)
nsa_ips=("11.0.0.0/8" "7.0.0.0/8" "104.118.255.0/24")  # DoD/NSA-related
fbi_ips=("153.31.0.0/16" "149.101.100.0/22" "104.16.41.0/24")  # FBI-related

# Domains to redirect to 0.0.0.0 in /etc/hosts
echo "0.0.0.0 nsa.gov www.nsa.gov ic.gov" >> /etc/hosts
echo "0.0.0.0 fbi.gov www.fbi.gov tips.fbi.gov" >> /etc/hosts
