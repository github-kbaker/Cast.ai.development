# Kubernetes On-Premises Cluster Setup
Complete automated setup for production-ready Kubernetes clusters using kubeadm.

## Quick Start (30-45 minutes)

### Prerequisites
- Ubuntu 20.04/22.04 LTS
- 2GB RAM minimum (4GB recommended)
- 2 CPU cores minimum
- Root/sudo access

### Setup Steps

**All Nodes (Master + Workers):**
```bash
git clone https://github.com/github-kbaker/DAG_health_monitor.git
cd DAG_health_monitor/k8s-onprem
sudo ./scripts/01-prepare-node.sh

sudo ./scripts/02-init-master.sh
./scripts/03-install-cni.sh
./scripts/04-install-helm.sh
./scripts/05-deploy-sample-app

sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> ...

kubectl get nodes
kubectl get pods -A

