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

if [ -n "$LINODE_CLI_TOKEN" ]; then

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

fi

if [ -n "$CLOUDFLARE_TOKEN" ]; then

curl -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE/dns_records?name=$CLOUDFLARE_NAME" \
  -H "Content-Type:application/json" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  | jq -r '.result[] | "\(.id) \(.content)"' \
  | tee entries.txt
fi

grep -v '^ *#' < external-ips.txt | while IFS= read -r ip; do
  grep "$ip" entries.txt || \
    curl -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE/dns_records" \
      -H "Content-Type:application/json" \
      -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
      --data "{\"type\":\"A\",\"name\":\"$CLOUDFLARE_NAME\",\"content\":\"$ip\",\"ttl\":120,\"proxied\":false}"
done

# shellcheck disable=SC2094
grep -oE '\b[^ ]+$' < entries.txt | while IFS= read -r ip; do
  # shellcheck disable=SC2094
  id=$(grep "$ip" entries.txt | grep -oE '^[^ ]+')
  grep "$ip" external-ips.txt || \
    curl -X DELETE "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE/dns_records/$id" \
      -H "Content-Type:application/json" \
      -H "Authorization: Bearer $CLOUDFLARE_TOKEN"
done


echo Done!

cp external-ips.txt external-ips-last.txt

done
