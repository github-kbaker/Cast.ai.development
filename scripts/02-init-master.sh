#!/bin/bash
set -e
GREEN='33[0;32m'
BLUE='33[0;34m'
NC='33[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

log_info "Initializing Kubernetes master..."
POD_NETWORK_CIDR="192.168.0.0/16"
API_SERVER_ADVERTISE_ADDRESS=$(hostname -I | awk '{print $1}')

kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR --apiserver-advertise-address=$API_SERVER_ADVERTISE_ADDRESS

mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

JOIN_COMMAND=$(kubeadm token create --print-join-command)
echo "$JOIN_COMMAND" > /tmp/kubeadm-join-command.sh
chmod +x /tmp/kubeadm-join-command.sh

echo ""
echo -e "${BLUE}Worker Node Join Command:${NC}"
echo "$JOIN_COMMAND"
echo ""
log_info "✅ Master initialized! Save the join command above."
