#!/bin/bash

# Deploy script for Node.js application to GKE
# Usage: ./deploy.sh [staging|production]

set -e

ENVIRONMENT=${1:-staging}
NAMESPACE=$ENVIRONMENT

echo "Deploying to $ENVIRONMENT environment on GKE..."

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply ConfigMap
kubectl apply -f k8s/configmap.yaml -n $NAMESPACE

# Apply Secrets (you need to update the secret.yaml with your actual values)
echo "Please update k8s/secret.yaml with your actual secret values before proceeding"
# kubectl apply -f k8s/secret.yaml -n $NAMESPACE

# Apply Deployment
kubectl apply -f k8s/deployment.yaml -n $NAMESPACE

# Apply Service
kubectl apply -f k8s/service.yaml -n $NAMESPACE

# Apply HPA for automatic scaling
kubectl apply -f k8s/hpa.yaml -n $NAMESPACE

# Apply Pod Disruption Budget
kubectl apply -f k8s/pdb.yaml -n $NAMESPACE

# Apply GKE-specific resources (only for production)
if [ "$ENVIRONMENT" = "production" ]; then
    echo "Applying production GKE resources..."
    
    # Apply Frontend Config for SSL redirect
    kubectl apply -f k8s/frontend-config.yaml -n $NAMESPACE
    
    # Apply Managed Certificate
    kubectl apply -f k8s/managed-certificate.yaml -n $NAMESPACE
    
    # Apply Ingress
    kubectl apply -f k8s/ingress.yaml -n $NAMESPACE
    
    echo "Production deployment completed. SSL certificate will be provisioned automatically."
fi

echo "Deployment completed for $ENVIRONMENT environment"
echo "Check deployment status with: kubectl get pods -n $NAMESPACE"
echo "Check HPA status with: kubectl get hpa -n $NAMESPACE" 