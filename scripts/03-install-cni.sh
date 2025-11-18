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
