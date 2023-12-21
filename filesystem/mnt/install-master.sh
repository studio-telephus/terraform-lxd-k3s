#!/usr/bin/env bash
: "${RANDOM_STRING?}"
: "${CONTAINER_K3S_MYSQL_IP?}"
: "${CONTAINER_K3S_LB_IP?}"
: "${MYSQL_K3S_USERNAME?}"
: "${MYSQL_K3S_PASSWORD?}"
: "${MYSQL_K3S_DATABASE?}"
: "${K3S_TOKEN?}"

# env > /tmp/env.out

apt-get update
apt-get install -y openssl curl

export K3S_DATASTORE_ENDPOINT="mysql://$MYSQL_K3S_USERNAME:$MYSQL_K3S_PASSWORD@tcp($CONTAINER_K3S_MYSQL_IP:3306)/$MYSQL_K3S_DATABASE"
# echo "K3S_DATASTORE_ENDPOINT=$K3S_DATASTORE_ENDPOINT"

curl -sfL https://get.k3s.io | sh -s - server --disable servicelb --node-taint CriticalAddonsOnly=true:NoExecute --tls-san $CONTAINER_K3S_LB_IP --token $K3S_TOKEN
ˇ
sed "s/127.0.0.1/$CONTAINER_K3S_LB_IP/g" /etc/rancher/k3s/k3s.yaml > /tmp/kubeconfig.local

# cat /var/lib/rancher/k3s/server/node-token

k3s check-config

echo "K3S master instance ready!"
