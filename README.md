# EKS WebApp  Node.js + Express on Amazon EKS

This project is a production-ready Node.js + Express web application packaged in Docker and deployed to Amazon EKS (Elastic Kubernetes Service). It includes Kubernetes manifests and shell scripts to build, push, deploy, and clean up the stack.

## Features

- Node.js 18 + Express web server
- HTML dashboard (`GET /`) showing app name, version, environment, and uptime
- Health endpoint (`GET /health`) for liveness/readiness probes
- Metadata endpoint (`GET /api/info`) returning JSON app info
- Multi-stage Dockerfile with non-root runtime user
- Kubernetes manifests (Deployment, Service, HPA, ConfigMap, Secret, Namespace)
- Shell scripts for:
  - Building and pushing Docker image to ECR
  - Deploying manifests to EKS
  - Cleaning up all resources and ECR repo

---

## Prerequisites

Make sure you have the following installed and configured:

- AWS CLI (configured with credentials and default region `us-east-1`)
- Docker (with permission to run Docker commands)
- `kubectl` (configured to talk to your EKS cluster)
- `eksctl` (optional, for creating the EKS cluster)
- An existing EKS cluster named `eks-beginner-cluster` in `us-east-1`
- Bash shell (for running the scripts)

---

## Project Structure

```text
.
├── app.js
├── package.json
├── Dockerfile
├── .dockerignore
├── k8s
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── hpa.yaml
└── scripts
    ├── build-push.sh
    ├── deploy.sh
    └── cleanup.sh
```

---

## One-time Setup

1. **Clone or copy the project files** into a directory on your machine.

2. **Make scripts executable**:

   ```bash
   chmod +x scripts/*.sh
   ```

3. **Replace AWS Account ID placeholders**

   All references to your AWS account ID use the placeholder `<AWS_ACCOUNT_ID>`. Set your AWS account ID and replace:

   ```bash
   export AWS_ACCOUNT_ID="<your-aws-account-id>"
   grep -rl "<AWS_ACCOUNT_ID>" . | xargs sed -i "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/g"
   ```

   > On macOS with BSD `sed`, use `sed -i ''` instead of `sed -i`.

4. **(Optional) Inspect and adjust ConfigMap and Secret**

   - `k8s/configmap.yaml`  change `APP_NAME`, `APP_VERSION`, `APP_ENV` if desired.
   - `k8s/secret.yaml`  replace `API_KEY` with your own base64-encoded value if you need a real secret.

---

## Build and Push Docker Image

Use the provided script to build and push the Docker image to Amazon ECR.

```bash
./scripts/build-push.sh
```

- Builds the image using the local `Dockerfile`.
- Ensures ECR repository `eks-webapp` exists (creates it if necessary).
- Pushes the image to:

  ```
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/eks-webapp:latest
  ```

You can optionally specify a custom tag:

```bash
./scripts/build-push.sh v1.0.0
```

---

## Deploy to Amazon EKS

Deploy all Kubernetes manifests to the `eks-beginner-cluster` EKS cluster:

```bash
./scripts/deploy.sh
```

The script will:

- Apply the `webapp` namespace.
- Apply ConfigMap and Secret.
- Apply Deployment, Service, and HPA.
- Wait for the Deployment rollout to complete.
- Poll until the LoadBalancer hostname becomes available.
- Output the external URL (e.g., `http://<elb-hostname>`).

---

## Verify the Deployment

Once `deploy.sh` prints the LoadBalancer hostname, open it in your browser:

```bash
# Example
open "http://<your-lb-hostname>"      # macOS
# or
xdg-open "http://<your-lb-hostname>"  # Linux
```

You should see the HTML dashboard with:

- App name
- Version
- Environment
- Uptime
- API Key configured status

You can also verify the health and info endpoints:

```bash
curl "http://<your-lb-hostname>/health"
curl "http://<your-lb-hostname>/api/info"
```

For Kubernetes-level checks:

```bash
kubectl get pods -n webapp
kubectl get svc -n webapp
kubectl get hpa -n webapp
```

---

## Cleanup

To remove all Kubernetes resources and delete the ECR repository:

```bash
./scripts/cleanup.sh
```

This will:

- Delete HPA, Service, Deployment, Secret, ConfigMap, and Namespace.
- Delete the `eks-webapp` ECR repository (and all its images) in `us-east-1`.

---

## Notes

- The HPA uses CPU utilization metrics (`autoscaling/v2`) and assumes that the metrics server is installed in your cluster.
- All configuration values are centralized in the ConfigMap and Secret to keep the Deployment spec clean and environment-agnostic.
- The Docker image runs as a non-root user for improved security.
