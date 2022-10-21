#!/usr/bin/env bash

set -e

echo starting external-dns-host-network...

touch external-ips-last.txt

while true; do

sleep 2

touch /tmp/healthy

kubectl describe node | grep -oE 'ExternalIP:.*' | cut -f2 -d':' | \
  grep -oE '[0-9.]+\.[0-9.]+' > external-ips.txt || continue

diff -q external-ips.txt external-ips-last.txt && continue

echo "new external ip addresses detected:"
cat external-ips.txt

if [ -n "$LINODE_CLI_TOKEN" ]; then

  echo linode token detected, updating LINODE_TAG="$LINODE_TAG" \
    SPECIAL_DOMAIN="$SPECIAL_DOMAIN" SPECIAL_TARGET="$SPECIAL_TARGET"

  linode-cli domains list --format 'id' --tag "$LINODE_TAG" --json \
    | python -m json.tool | grep '"id"' | cut -f2 -d':' | grep -oE '[^ ]+' \
    | tee domains.txt

  grep -v '^ *#' < domains.txt | while IFS= read -r domain; do

    echo "checking $domain"

    linode-cli domains records-list "$domain" --format 'id,type,name,target' \
      --json | tee domain-info.json

    grep -oE '\{"id"[^}]+' domain-info.json \
      | grep '"type": "A", "name": "", "target": "' \
      | tee domain-targets.txt

    if [ "$domain" == "$SPECIAL_DOMAIN" ]; then
      grep -oE '\{"id"[^}]+' domain-info.json \
        | grep "\"type\": \"A\", \"name\": \"$SPECIAL_TARGET\", \"target\": \"" \
        | tee -a domain-targets.txt
    fi

    grep -v '^ *#' < external-ips.txt | while IFS= read -r ip; do

      echo "checking external ip $ip"

      grep -v "$ip" domain-targets.txt > domain-targets.txt1 || true
      mv domain-targets.txt1 domain-targets.txt || true

      grep -q "\"type\": \"A\", \"name\": \"\", \"target\": \"$ip\"" \
        domain-info.json && continue

      echo "adding $ip to root"

      linode-cli domains records-create "$domain" --type A --name "" \
        --target "$ip" --ttl_sec 300

      if [ "$domain" == "$SPECIAL_DOMAIN" ]; then
        grep "\"type\": \"A\", \"name\": \"$SPECIAL_TARGET\", \"target\": \"$ip\"" \
          -q domain-info.json && continue
        echo "adding $ip to $SPECIAL_DOMAIN"
        linode-cli domains records-create "$domain" --type A --target "$ip" \
          --name "$SPECIAL_DOMAIN"  --ttl_sec 300
      fi

      echo added

    done

    grep id --color domain-targets.txt || true

    grep -oE '"id": [0-9]+' domain-targets.txt | cut -f2 -d':' \
      | grep -oE '[0-9]+' | while IFS= read -r record; do
      echo "deleting $domain record $record"
      linode-cli domains records-delete "$domain" "$record"
    done

  done

fi  # [ -n "$LINODE_CLI_TOKEN" ]

if [ -n "$CLOUDFLARE_TOKEN" ]; then

  echo cloudflare token detected

  curl -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE/dns_records?name=$CLOUDFLARE_NAME" \
    -H "Content-Type:application/json" \
    -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
    | jq -r '.result[] | "\(.id) \(.content)"' \
    | tee entries.txt

  grep -v '^ *#' < external-ips.txt | while IFS= read -r ip; do
    echo "checking if $ip needs to be added"
    grep "$ip" entries.txt || \
      curl -s -D - -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE/dns_records" \
        -H "Content-Type:application/json" \
        -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
        --data "{\"type\":\"A\",\"name\":\"$CLOUDFLARE_NAME\",\"content\":\"$ip\",\"ttl\":120,\"proxied\":false}"
  done

  # shellcheck disable=SC2094
  grep -oE '\b[^ ]+$' < entries.txt | while IFS= read -r ip; do
    # shellcheck disable=SC2094
    id=$(grep "$ip" entries.txt | grep -oE '^[^ ]+')
    echo "checking if $ip needs to be removed"
    grep "$ip" external-ips.txt || \
      curl -s -D - -X DELETE "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE/dns_records/$id" \
        -H "Content-Type:application/json" \
        -H "Authorization: Bearer $CLOUDFLARE_TOKEN"
  done

fi  # [ -n "$CLOUDFLARE_TOKEN" ]

echo Done!

cp external-ips.txt external-ips-last.txt

done
