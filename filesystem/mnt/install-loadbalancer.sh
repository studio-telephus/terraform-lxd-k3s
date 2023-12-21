#!/usr/bin/env bash
: "${RANDOM_STRING?}"
: "${CONTAINER_K3S_LB_IP?}"
: "${CONTAINER_K3S_M1_IP?}"
: "${CONTAINER_K3S_M2_IP?}"

# env > /tmp/env.out

apt-get update
apt-get install -y curl gnupg2 netcat-traditional openssl net-tools haproxy

# sleep 10
cp -pr /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig

# TODO: add master servers from environment loop with filter
cat > /tmp/k3s_6_haproxy.cfg.append << EOF
listen kubernetes-apiserver-https
bind $CONTAINER_K3S_LB_IP:6443
mode tcp
option log-health-checks
timeout client 3h
timeout server 3h
server master1 $CONTAINER_K3S_M1_IP:6443 check check-ssl verify none inter 10000
server master2 $CONTAINER_K3S_M2_IP:6443 check check-ssl verify none inter 10000
balance roundrobin
EOF

cat /tmp/k3s_6_haproxy.cfg.append >> /etc/haproxy/haproxy.cfg
systemctl restart haproxy

echo "K3S load balancer ready!"
