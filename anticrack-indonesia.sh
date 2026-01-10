#!/bin/bash
domains=("indonesia.go.id" "setkab.go.id" "kemlu.go.id" "kemenkeu.go.id" "kemenag.go.id" "kemenkes.go.id" "kemenperin.go.id" "kemendag.go.id" "esdm.go.id" "kemenaker.go.id" "kemenkumham.go.id" "kemenpar.go.id" "kemendikbud.go.id" "kemenpora.go.id" "kemenkominfo.go.id" "bkpm.go.id" "imigrasi.go.id" "pajak.go.id" "klhk.go.id" "dephub.go.id" "bappenas.go.id")
for domain in "${domains[@]}"; do
  echo "127.0.0.1 $domain" | sudo tee -a /etc/hosts
done
