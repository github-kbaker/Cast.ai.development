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
