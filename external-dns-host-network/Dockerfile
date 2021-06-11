FROM python:3.9
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" && \
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
  kubectl version --client

RUN pip3 install linode-cli --upgrade
ENV LINODE_CLI_TOKEN=""
ENV LINODE_TAG="minthe"
ENV SPECIAL_DOMAIN="114584"
ENV SPECIAL_TARGET="minthe"
WORKDIR /app
COPY --chmod=755 external-dns-host-network.sh /app/
CMD /app/external-dns-host-network.sh
