#!/bin/bash

# GKE Cleanup Script
# This script removes all resources created for the Node.js application

set -e

echo "🧹 Cleaning up GKE resources..."

# Confirm before proceeding
read -p "Are you sure you want to delete all resources? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

# Delete Kubernetes resources
echo "🗑️  Deleting Kubernetes resources..."

# Delete from production namespace
kubectl delete -f k8s/ingress.yaml -n production --ignore-not-found=true
kubectl delete -f k8s/managed-certificate.yaml -n production --ignore-not-found=true
kubectl delete -f k8s/frontend-config.yaml -n production --ignore-not-found=true
kubectl delete -f k8s/hpa.yaml -n production --ignore-not-found=true
kubectl delete -f k8s/pdb.yaml -n production --ignore-not-found=true
kubectl delete -f k8s/service.yaml -n production --ignore-not-found=true
kubectl delete -f k8s/deployment.yaml -n production --ignore-not-found=true
kubectl delete -f k8s/configmap.yaml -n production --ignore-not-found=true

# Delete from staging namespace
kubectl delete -f k8s/hpa.yaml -n staging --ignore-not-found=true
kubectl delete -f k8s/pdb.yaml -n staging --ignore-not-found=true
kubectl delete -f k8s/service.yaml -n staging --ignore-not-found=true
kubectl delete -f k8s/deployment.yaml -n staging --ignore-not-found=true
kubectl delete -f k8s/configmap.yaml -n staging --ignore-not-found=true

# Delete secrets
kubectl delete secret gitlab-registry-secret -n production --ignore-not-found=true
kubectl delete secret gitlab-registry-secret -n staging --ignore-not-found=true

# Delete namespaces
kubectl delete namespace production --ignore-not-found=true
kubectl delete namespace staging --ignore-not-found=true

# Delete static IP
echo "🌐 Deleting static IP..."
gcloud compute addresses delete node-app-ip --global --quiet

echo "✅ Cleanup completed successfully!"
echo ""
echo "📋 Note: If you want to completely remove the cluster, run:"
echo "   gcloud container clusters delete <cluster-name> --zone=<zone>" 