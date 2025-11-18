#!/bin/bash
echo "Creating Kubernetes setup files..."

# Create prepare-node script
cat > scripts/01-prepare-node.sh << 'EOF'
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
EOF

chmod +x scripts/01-prepare-node.sh
echo "✓ Created 01-prepare-node.sh"

# Create init-master script
cat > scripts/02-init-master.sh << 'EOF'
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
EOF

chmod +x scripts/02-init-master.sh
echo "✓ Created 02-init-master.sh"

# Create CNI install script
cat > scripts/03-install-cni.sh << 'EOF'
#!/bin/bash
set -e
GREEN='33[0;32m'
NC='33[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

log_info "Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml

log_info "Waiting for Calico to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s

log_info "✅ Calico CNI installed!"
kubectl get nodes
EOF

chmod +x scripts/03-install-cni.sh
echo "✓ Created 03-install-cni.sh"

# Create Helm install script
cat > scripts/04-install-helm.sh << 'EOF'
#!/bin/bash
set -e
GREEN='33[0;32m'
NC='33[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

log_info "Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable
helm repo update

log_info "✅ Helm installed!"
helm version
EOF

chmod +x scripts/04-install-helm.sh
echo "✓ Created 04-install-helm.sh"

# Create sample app script
cat > scripts/05-deploy-sample-app.sh << 'EOF'
#!/bin/bash
set -e
GREEN='33[0;32m'
NC='33[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

NAMESPACE="web-demo"
log_info "Deploying sample NGINX app..."

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
helm install my-nginx bitnami/nginx --namespace $NAMESPACE --wait

log_info "✅ Sample app deployed!"
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE
echo ""
echo "Access with: kubectl port-forward -n $NAMESPACE svc/my-nginx 8080:80"
EOF

chmod +x scripts/05-deploy-sample-app.sh
echo "✓ Created 05-deploy-sample-app.sh"

echo ""
echo "✅ All scripts created successfully!"
echo ""
echo "Location: ~/k8s-onprem/scripts/"
ls -l ~/k8s-onprem/scripts/
