#!/usr/bin/env bash

set -ex

echo Starting ip update process for LINODE_TAG="$LINODE_TAG" \
  SPECIAL_DOMAIN="$SPECIAL_DOMAIN" SPECIAL_TARGET="$SPECIAL_TARGET"

touch external-ips-last.txt

while true; do

sleep 2

touch /tmp/healthy

kubectl describe node | grep -oE 'ExternalIP:.*' | cut -f2 -d':' \
  | grep -oE '[0-9.]+' > external-ips.txt

diff -q external-ips.txt external-ips-last.txt && continue

linode-cli domains list --format 'id' --tag "$LINODE_TAG" --json \
  | python -m json.tool | grep '"id"' | cut -f2 -d':' | grep -oE '[^ ]+' \
  > domains.txt

grep -v '^ *#' < domains.txt | while IFS= read -r domain; do

  linode-cli domains records-list "$domain" --format 'id,type,name,target' \
    --json > domain-info.json

  grep -oE '\{"id"[^}]+' domain-info.json \
    | grep '"type": "A", "name": "", "target": "' \
    > domain-targets.txt

  if [ "$domain" == "$SPECIAL_DOMAIN" ]; then
    grep -oE '\{"id"[^}]+' domain-info.json \
      | grep "\"type\": \"A\", \"name\": \"$SPECIAL_TARGET\", \"target\": \"" \
      >> domain-targets.txt
  fi

  grep -v '^ *#' < external-ips.txt | while IFS= read -r ip; do

    grep -v "$ip" domain-targets.txt > domain-targets.txt1 || true
    mv domain-targets.txt1 domain-targets.txt || true

    grep -q "\"type\": \"A\", \"name\": \"\", \"target\": \"$ip\"" \
      domain-info.json && continue

    linode-cli domains records-create "$domain" --type A --name "" \
      --target "$ip" --ttl_sec 300

    if [ "$domain" == "$SPECIAL_DOMAIN" ]; then
      grep "\"type\": \"A\", \"name\": \"$SPECIAL_TARGET\", \"target\": \"$ip\"" \
        -q domain-info.json && continue
      linode-cli domains records-create "$domain" --type A --target "$ip" \
        --name "$SPECIAL_DOMAIN"  --ttl_sec 300
    fi

  done

  grep id --color domain-targets.txt || true

  grep -oE '"id": [0-9]+' domain-targets.txt | cut -f2 -d':' \
    | grep -oE '[0-9]+' | while IFS= read -r record; do
    linode-cli domains records-delete "$domain" "$record"
  done

done

echo Done!

cp external-ips.txt external-ips-last.txt

done
