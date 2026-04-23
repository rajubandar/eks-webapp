#!/usr/bin/env bash
# Clean up Kubernetes resources and ECR repository

set -euo pipefail

NAMESPACE="webapp"
AWS_REGION="us-east-1"
ECR_REPO_NAME="eks-webapp"

echo "[cleanup] Cleaning up Kubernetes resources and ECR repository..."

# Check required commands
for cmd in kubectl aws; do
  if ! command -t "${cmd}" >/dev/null 2>&1; then
    echo "[cleanup] ERROR: '${cmd}' is not installed or not in PATH"
    exit 1
  fi
done

# Delete Kubernetes resources (order from dependent to base)
echo "[cleanup] Deleting HPA..."
kubectl delete -f k8s/hpa.yaml --ignore-not-found

echo "[cleanup] Deleting Service..."
kubectl delete -f k8s/service.yaml --ignore-not-found

echo "[cleanup] Deleting Deployment..."
kubectl delete -f k8s/deployment.yaml --ignore-not-found

echo "[cleanup] Deleting Secret..."
kubectl delete -f k8s/secret.yaml --ignore-not-found

echo "[cleanup] Deleting ConfigMap..."
kubectl delete -f k8s/configmap.yaml --ignore-not-found

echo "[cleanup] Deleting Namespace (this will remove remaining resources within it)..."
kubectl delete -f k8s/namespace.yaml --ignore-not-found

# Delete ECR repository and its images
echo "[cleanup] Deleting ECR repository '${ECR_REPO_NAME}' (if it exists)..."
if aws ecr describe-repositories --repository-names "${ECR_REPO_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  aws ecr delete-repository \
    --repository-name "${ECR_REPO_NAME}" \
    --force \
    --region "${AWS_REGION}" >/dev/null
  echo "[cleanup] ECR repository '${ECR_REPO_NAME}' deleted."
else
  echo "[cleanup] ECR repository '${ECR_REPO_NAME}' not found. Skipping."
fi

echo "[cleanup] Cleanup completed."
