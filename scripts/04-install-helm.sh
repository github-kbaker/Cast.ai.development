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
