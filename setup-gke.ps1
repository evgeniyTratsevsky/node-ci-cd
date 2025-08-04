# GKE Setup Script for Node.js CI/CD (PowerShell)
# This script helps set up the initial GKE configuration

Write-Host "🚀 Setting up GKE for Node.js CI/CD..." -ForegroundColor Green

# Check if gcloud is installed
try {
    gcloud --version | Out-Null
} catch {
    Write-Host "❌ gcloud CLI is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}

# Check if kubectl is installed
try {
    kubectl version --client | Out-Null
} catch {
    Write-Host "❌ kubectl is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "https://kubernetes.io/docs/tasks/tools/" -ForegroundColor Yellow
    exit 1
}

# Get current project
$PROJECT_ID = gcloud config get-value project
Write-Host "📋 Current GCP Project: $PROJECT_ID" -ForegroundColor Cyan

# Enable required APIs
Write-Host "🔧 Enabling required APIs..." -ForegroundColor Yellow
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable dns.googleapis.com

# Get cluster information
Write-Host "📊 Available GKE clusters:" -ForegroundColor Cyan
gcloud container clusters list

# Ask for cluster name
$CLUSTER_NAME = Read-Host "Enter your GKE cluster name"
$CLUSTER_LOCATION = Read-Host "Enter your GKE cluster zone/region"

# Get cluster credentials
Write-Host "🔐 Getting cluster credentials..." -ForegroundColor Yellow
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$CLUSTER_LOCATION

# Create static IP for ingress
Write-Host "🌐 Creating static IP for ingress..." -ForegroundColor Yellow
gcloud compute addresses create node-app-ip --global

# Get the static IP
$STATIC_IP = gcloud compute addresses describe node-app-ip --global --format="value(address)"
Write-Host "✅ Static IP created: $STATIC_IP" -ForegroundColor Green

# Create GitLab registry secret
Write-Host "🔑 Creating GitLab registry secret..." -ForegroundColor Yellow
$GITLAB_USERNAME = Read-Host "Enter your GitLab username"
$GITLAB_TOKEN = Read-Host "Enter your GitLab access token" -AsSecureString
$GITLAB_EMAIL = Read-Host "Enter your GitLab email"

# Convert secure string to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GITLAB_TOKEN)
$GITLAB_TOKEN_PLAIN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

kubectl create secret docker-registry gitlab-registry-secret `
  --docker-server=registry.gitlab.com `
  --docker-username=$GITLAB_USERNAME `
  --docker-password=$GITLAB_TOKEN_PLAIN `
  --docker-email=$GITLAB_EMAIL `
  --dry-run=client -o yaml > k8s/gitlab-registry-secret.yaml

Write-Host "✅ GitLab registry secret created in k8s/gitlab-registry-secret.yaml" -ForegroundColor Green

# Create namespaces
Write-Host "📁 Creating namespaces..." -ForegroundColor Yellow
kubectl apply -f k8s/namespace.yaml

# Apply secrets to both namespaces
Write-Host "🔐 Applying secrets to namespaces..." -ForegroundColor Yellow
kubectl apply -f k8s/gitlab-registry-secret.yaml -n staging
kubectl apply -f k8s/gitlab-registry-secret.yaml -n production

Write-Host ""
Write-Host "🎉 GKE setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Update k8s/deployment.yaml with your GitLab registry path"
Write-Host "2. Update k8s/ingress.yaml and k8s/managed-certificate.yaml with your domain"
Write-Host "3. Run: ./deploy.sh staging"
Write-Host "4. Run: ./deploy.sh production"
Write-Host ""
Write-Host "📊 Useful commands:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -n staging"
Write-Host "  kubectl get pods -n production"
Write-Host "  kubectl get ingress -n production"
Write-Host "  kubectl get managedcertificate -n production"
Write-Host ""
Write-Host "🌐 Your static IP: $STATIC_IP" -ForegroundColor Yellow
Write-Host "   Point your domain's A record to this IP address" -ForegroundColor Yellow 