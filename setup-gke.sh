#!/bin/bash

# GKE Setup Script for Node.js CI/CD
# This script helps set up the initial GKE configuration

set -e

echo "🚀 Setting up GKE for Node.js CI/CD..."

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first:"
    echo "https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first:"
    echo "https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project)
echo "📋 Current GCP Project: $PROJECT_ID"

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable dns.googleapis.com

# Get cluster information
echo "📊 Available GKE clusters:"
gcloud container clusters list

# Ask for cluster name
read -p "Enter your GKE cluster name: " CLUSTER_NAME
read -p "Enter your GKE cluster zone/region: " CLUSTER_LOCATION

# Get cluster credentials
echo "🔐 Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$CLUSTER_LOCATION

# Create static IP for ingress
echo "🌐 Creating static IP for ingress..."
gcloud compute addresses create node-app-ip --global

# Get the static IP
STATIC_IP=$(gcloud compute addresses describe node-app-ip --global --format="value(address)")
echo "✅ Static IP created: $STATIC_IP"

# Update ingress configuration with static IP
echo "📝 Updating ingress configuration..."
sed -i.bak "s/kubernetes.io\/ingress.global-static-ip-name: \"node-app-ip\"/kubernetes.io\/ingress.global-static-ip-name: \"node-app-ip\"/" k8s/ingress.yaml

# Create GitLab registry secret
echo "🔑 Creating GitLab registry secret..."
read -p "Enter your GitLab username: " GITLAB_USERNAME
read -p "Enter your GitLab access token: " GITLAB_TOKEN
read -p "Enter your GitLab email: " GITLAB_EMAIL

kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=registry.gitlab.com \
  --docker-username=$GITLAB_USERNAME \
  --docker-password=$GITLAB_TOKEN \
  --docker-email=$GITLAB_EMAIL \
  --dry-run=client -o yaml > k8s/gitlab-registry-secret.yaml

echo "✅ GitLab registry secret created in k8s/gitlab-registry-secret.yaml"

# Create namespaces
echo "📁 Creating namespaces..."
kubectl apply -f k8s/namespace.yaml

# Apply secrets to both namespaces
echo "🔐 Applying secrets to namespaces..."
kubectl apply -f k8s/gitlab-registry-secret.yaml -n staging
kubectl apply -f k8s/gitlab-registry-secret.yaml -n production

echo ""
echo "🎉 GKE setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Update k8s/deployment.yaml with your GitLab registry path"
echo "2. Update k8s/ingress.yaml and k8s/managed-certificate.yaml with your domain"
echo "3. Run: ./deploy.sh staging"
echo "4. Run: ./deploy.sh production"
echo ""
echo "📊 Useful commands:"
echo "  kubectl get pods -n staging"
echo "  kubectl get pods -n production"
echo "  kubectl get ingress -n production"
echo "  kubectl get managedcertificate -n production"
echo ""
echo "🌐 Your static IP: $STATIC_IP"
echo "   Point your domain's A record to this IP address" 