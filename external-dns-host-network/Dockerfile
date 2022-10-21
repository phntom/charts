# DOCKER_BUILDKIT=1 docker build . -f Dockerfile --pull -t phntom/external-dns-host-network:0.0.13

FROM python:3.9
RUN apt-get update && apt-get install jq -y && \
  pip3 install linode-cli --upgrade --no-cache && \
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" && \
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
  kubectl version --client && \
  jq --version && \
  apt-get clean autoclean && \
  apt-get autoremove --yes && \
  rm -rfv /var/lib/{apt,dpkg,cache,log}/

ENV LINODE_CLI_TOKEN=""
ENV LINODE_TAG="test"

ENV CLOUDFLARE_TOKEN=""
ENV CLOUDFLARE_ZONE=""
ENV CLOUDFLARE_NAME=""
ENV CLOUDFLARE_TTL="60"

ENV SPECIAL_DOMAIN="1337"
ENV SPECIAL_TARGET="test"

WORKDIR /app
COPY --chmod=755 external-dns-host-network.sh /app/
CMD /app/external-dns-host-network.sh
