#!/bin/bash
domains=("gov.uk" "cabinetoffice.gov.uk" "defra.gov.uk" "education.gov.uk" "dft.gov.uk" "dh.gov.uk" "fcdo.gov.uk" "hmtreasury.gov.uk" "homeoffice.gov.uk" "mod.uk" "justice.gov.uk" "dwp.gov.uk" "hmrc.gov.uk" "no10.gov.uk" "hmpo.gov.uk" "cma.gov.uk" "ofsted.gov.uk" "nationalarchives.gov.uk" "companieshouse.gov.uk" "dvla.gov.uk")
for domain in "${domains[@]}"; do
  echo "127.0.0.1 $domain" | sudo tee -a /etc/hosts
done
