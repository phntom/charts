#!/usr/bin/env bash

set -e

echo starting external-dns-host-network...

touch external-ips-last.txt
touch internal-ips-last.txt

while true; do

sleep 2

touch /tmp/healthy

kubectl describe node | grep -oE 'ExternalIP:.*' | cut -f2 -d':' | \
  grep -oE '[0-9.]+\.[0-9.]+' > external-ips.txt || continue

kubectl describe node | grep -oE 'InternalIP:[ :0-9a-f]*$' | cut -f2- -d':' | \
  grep -oE '[^ ]+' | sed 's/:0:0$/::/' > internal-ips.txt || continue

diff -q external-ips.txt external-ips-last.txt && \
  diff -q internal-ips.txt internal-ips-last.txt && \
  continue

diff -q external-ips.txt external-ips-last.txt || echo "new external ip addresses detected"
diff -q internal-ips.txt internal-ips-last.txt || echo "new internal ip addresses detected"
cat external-ips.txt
cat internal-ips.txt

if [ -n "$CLOUDFLARE_TOKEN" ]; then

  echo cloudflare token detected

  curl -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records?name=${CLOUDFLARE_NAME}&type=A" \
    -H "Content-Type:application/json" \
    -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
    | jq -r '.result[] | "\(.id) \(.content)"' \
    | tee entries.txt

  grep -v '^ *#' < external-ips.txt | while IFS= read -r ip; do
    echo "checking if $ip needs to be added"
    grep "$ip" entries.txt || \
      curl -s -D - -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records" \
        -H "Content-Type:application/json" \
        -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
        --data "{\"type\":\"A\",\"name\":\"${CLOUDFLARE_NAME}\",\"content\":\"$ip\",\"ttl\":${CLOUDFLARE_TTL},\"proxied\":false}"
  done

  # shellcheck disable=SC2094
  grep -oE '\b[^ ]+$' < entries.txt | while IFS= read -r ip; do
    # shellcheck disable=SC2094
    id=$(grep "$ip" entries.txt | grep -oE '^[^ ]+')
    echo "checking if $ip needs to be removed"
    grep "$ip" external-ips.txt || \
      curl -s -D - -X DELETE "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records/${id}" \
        -H "Content-Type:application/json" \
        -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}"
  done

  curl -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records?name=${CLOUDFLARE_NAME}&type=AAAA" \
    -H "Content-Type:application/json" \
    -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
    | jq -r '.result[] | "\(.id) \(.content)"' \
    | tee entries.txt

  grep -v '^ *#' < internal-ips.txt | while IFS= read -r ip; do
    echo "checking if $ip needs to be added"
    grep "$ip" entries.txt || \
      curl -s -D - -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records" \
        -H "Content-Type:application/json" \
        -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
        --data "{\"type\":\"AAAA\",\"name\":\"${CLOUDFLARE_NAME}\",\"content\":\"$ip\",\"ttl\":${CLOUDFLARE_TTL},\"proxied\":false}"
  done

  # shellcheck disable=SC2094
  grep -oE '\b[^ ]+$' < entries.txt | while IFS= read -r ip; do
    # shellcheck disable=SC2094
    id=$(grep "$ip" entries.txt | grep -oE '^[^ ]+')
    echo "checking if $ip needs to be removed"
    grep "$ip" internal-ips.txt || \
      curl -s -D - -X DELETE "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/dns_records/${id}" \
        -H "Content-Type:application/json" \
        -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}"
  done

fi  # [ -n "$CLOUDFLARE_TOKEN" ]

echo Done!

cp external-ips.txt external-ips-last.txt
cp internal-ips.txt internal-ips-last.txt

done
