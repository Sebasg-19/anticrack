#!/bin/bash

# Block Greenland
countries="gl"

for country in $countries; do
  wget "https://www.ipdeny.com/ipblocks/data/aggregated/${country}-aggregated.zone" -O "/tmp/${country}.zone"
  while read -r ip; do
    iptables -A INPUT -s "$ip" -j DROP
  done < "/tmp/${country}.zone"
  rm "/tmp/${country}.zone"
done

echo "Greenland blocked."
