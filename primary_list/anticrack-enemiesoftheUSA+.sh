#!/bin/bash

# Block enemies and their allies
countries="cn ru ir kp by sy ve cu pk kh mm ni er ml cf bf ne"

for country in $countries; do
  wget "https://www.ipdeny.com/ipblocks/data/aggregated/${country}-aggregated.zone" -O "/tmp/${country}.zone"
  while read -r ip; do
    iptables -A INPUT -s "$ip" -j DROP
  done < "/tmp/${country}.zone"
  rm "/tmp/${country}.zone"
done

echo "Enemies and enemy allies blocked."
