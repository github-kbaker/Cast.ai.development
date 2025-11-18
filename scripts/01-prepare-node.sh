#!/bin/bash
set -e
RED='33[0;31m'
GREEN='33[0;32m'
NC='33[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Starting node preparation..."
if [ "$EUID" -ne 0 ]; then 
   log_error "Please run as root or with sudo"
   exit 1
fi

log_info "Updating system..."
apt update && apt upgrade -y

log_info "Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

log_info "Loading kernel modules..."
cat <<EOFMOD | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOFMOD
modprobe overlay
modprobe br_netfilter

log_info "Configuring sysctl..."
cat <<EOFSYS | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOFSYS
sysctl --system

log_info "Installing containerd..."
apt install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

log_info "Installing Kubernetes tools..."
apt-get install -y apt-transport-https ca-certificates curl gpg
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubeadm kubelet kubectl
apt-mark hold kubeadm kubelet kubectl
systemctl enable kubelet

log_info "✅ Node preparation complete!"
