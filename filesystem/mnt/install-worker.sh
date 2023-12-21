#!/usr/bin/env bash
: "${RANDOM_STRING?}"
: "${CONTAINER_K3S_LB_IP?}"
: "${K3S_TOKEN?}"

apt-get update
apt-get install -y openssl curl

curl -sfL https://get.k3s.io | K3S_URL=https://$CONTAINER_K3S_LB_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -
sleep 3

systemctl status k3s-agent

echo "K3S worker instance ready!"
