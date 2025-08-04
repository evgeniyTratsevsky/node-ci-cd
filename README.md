# Node.js CI/CD with GitLab and Kubernetes

This project demonstrates a complete CI/CD pipeline for a Node.js application using GitLab CI/CD and Kubernetes deployment.

## Project Structure

```
├── app.js                 # Main application file
├── package.json           # Node.js dependencies
├── Dockerfile            # Multi-stage Docker build
├── .gitlab-ci.yml        # GitLab CI/CD pipeline
├── k8s/                  # Kubernetes manifests
│   ├── namespace.yaml    # Namespace definitions
│   ├── deployment.yaml   # Application deployment
│   ├── service.yaml      # Service configuration
│   ├── ingress.yaml      # Ingress configuration
│   ├── configmap.yaml    # Configuration management
│   └── secret.yaml       # Secrets template
├── deploy.sh             # Deployment script
└── README.md             # This file
```

## Prerequisites

1. **GitLab Account** with a repository
2. **Google Cloud Platform (GCP) Account** with billing enabled
3. **Google Kubernetes Engine (GKE) Cluster** 
4. **GitLab Agent for Kubernetes** installed in your cluster
5. **Docker** for building container images
6. **gcloud CLI** and **kubectl** installed locally

## Setup Instructions

### 1. GKE Cluster Setup

1. **Create a GKE cluster** (if you don't have one):
   ```bash
   gcloud container clusters create node-app-cluster \
     --zone=us-central1-a \
     --num-nodes=3 \
     --enable-autoscaling \
     --min-nodes=1 \
     --max-nodes=10 \
     --enable-autorepair \
     --enable-autoupgrade
   ```

2. **Get cluster credentials**:
   ```bash
   gcloud container clusters get-credentials node-app-cluster --zone=us-central1-a
   ```

### 2. Initial GKE Configuration

Run the automated setup script:
```bash
chmod +x setup-gke.sh
./setup-gke.sh
```

This script will:
- Enable required GCP APIs
- Create a static IP for ingress
- Set up GitLab registry authentication
- Create namespaces
- Configure initial secrets

### 3. GitLab Repository Setup

1. Push this code to your GitLab repository
2. Go to your project's **Settings > CI/CD > Variables**
3. Add the following variables:
   - `KUBE_CONTEXT_STAGING`: Your staging Kubernetes context
   - `KUBE_CONTEXT_PRODUCTION`: Your production Kubernetes context

### 4. GitLab Agent for Kubernetes Setup

1. In your GitLab project, go to **Infrastructure > Kubernetes clusters**
2. Click **Connect a cluster**
3. Choose **GitLab Agent for Kubernetes**
4. Follow the installation instructions for your GKE cluster

### 5. Update Configuration Files

#### Update Docker Image Registry
In `k8s/deployment.yaml`, replace:
```yaml
image: registry.gitlab.com/your-group/your-project:latest
```
with your actual GitLab registry path.

#### Update Domain Names
1. In `k8s/ingress.yaml`, replace `yourdomain.com` with your actual domain
2. In `k8s/managed-certificate.yaml`, replace `yourdomain.com` with your actual domain
3. Point your domain's A record to the static IP created by the setup script

#### Configure Secrets
The setup script creates the GitLab registry secret automatically. If you need to update it:
```bash
kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=registry.gitlab.com \
  --docker-username=<your-gitlab-username> \
  --docker-password=<your-gitlab-access-token> \
  --docker-email=<your-email> \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 6. Initial Deployment

```bash
# Make deploy script executable
chmod +x deploy.sh

# Deploy to staging
./deploy.sh staging

# Deploy to production
./deploy.sh production
```

## CI/CD Pipeline

The pipeline consists of three stages:

1. **Test**: Runs tests on merge requests and main branch
2. **Build**: Builds and pushes Docker image to GitLab registry
3. **Deploy**: Deploys to staging and production (manual triggers)

### Pipeline Variables

The following GitLab CI/CD variables are automatically available:
- `CI_REGISTRY`: GitLab container registry URL
- `CI_REGISTRY_USER`: Registry username
- `CI_REGISTRY_PASSWORD`: Registry password
- `CI_PROJECT_PATH`: Project path in GitLab
- `CI_COMMIT_SHA`: Current commit SHA

## Kubernetes Resources

### Namespaces
- `staging`: For staging environment
- `production`: For production environment

### Deployment
- 3 replicas for high availability
- Resource limits and requests configured
- Health checks (liveness and readiness probes)
- Non-root user for security

### Service
- ClusterIP type for internal communication
- Exposes port 80, forwards to container port 3000

### Ingress
- SSL/TLS termination with Google Cloud Load Balancer
- Automatic certificate management with Google Managed Certificates
- Domain-based routing
- Global static IP for consistent access

## Monitoring and Health Checks

The application includes:
- `/health` endpoint for health checks
- Liveness probe to restart unhealthy pods
- Readiness probe to ensure traffic only goes to ready pods

## GKE-Specific Features

- **Automatic Scaling**: Horizontal Pod Autoscaler (HPA) for CPU and memory
- **High Availability**: Pod Disruption Budget ensures minimum availability
- **Managed SSL**: Google Managed Certificates for automatic SSL/TLS
- **Global Load Balancer**: Google Cloud Load Balancer with static IP
- **Node Auto-repair**: Automatic node health monitoring and repair
- **Node Auto-upgrade**: Automatic Kubernetes version upgrades

## Security Features

- Non-root user in Docker container
- Resource limits to prevent resource exhaustion
- Secrets management for sensitive data
- SSL/TLS encryption for external traffic
- GKE security features (Workload Identity, Binary Authorization, etc.)

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n staging
kubectl get pods -n production
```

### View Logs
```bash
kubectl logs -f deployment/node-app -n staging
```

### Check Services
```bash
kubectl get svc -n staging
kubectl get svc -n production
```

### Check Ingress and Certificates
```bash
kubectl get ingress -n production
kubectl get managedcertificate -n production
kubectl describe managedcertificate node-app-cert -n production
```

### Check HPA and Scaling
```bash
kubectl get hpa -n production
kubectl describe hpa node-app-hpa -n production
```

### Check Static IP
```bash
gcloud compute addresses list --global
```

## Next Steps

1. Add your application-specific tests to the CI pipeline
2. Configure monitoring and logging (Prometheus, Grafana, ELK stack)
3. Set up backup and disaster recovery procedures
4. Implement blue-green or canary deployments
5. Add security scanning to the pipeline

## Contributing

1. Create a feature branch
2. Make your changes
3. Create a merge request
4. The CI pipeline will automatically test your changes
5. After approval, merge to main branch for deployment