# DOCKER_BUILDKIT=1 docker build . -f Dockerfile --platform linux/amd64 --pull -t phntom/external-dns-host-network:0.0.14

FROM python:3.11-alpine
RUN apk --update add jq curl bash && \
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
  kubectl version --client && \
  jq --version

ENV CLOUDFLARE_TOKEN=""
ENV CLOUDFLARE_ZONE=""
ENV CLOUDFLARE_NAME=""
ENV CLOUDFLARE_TTL="60"

ENV SPECIAL_DOMAIN="1337"
ENV SPECIAL_TARGET="test"

WORKDIR /app
COPY --chmod=755 external-dns-host-network.sh /app/
CMD /app/external-dns-host-network.sh
