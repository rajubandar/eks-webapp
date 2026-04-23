#!/usr/bin/env bash
# Deploy all Kubernetes manifests to the EKS cluster and print LoadBalancer URL

set -euo pipefail

NAMESPACE="webapp"
AWS_REGION="us-east-1"
CLUSTER_NAME="eks-beginner-cluster"

echo "[deploy] Deploying to cluster '${CLUSTER_NAME}' in region '${AWS_REGION}'..."

# Check required commands
for cmd in kubectl aws; do
  if ! command -t "${cmd}" >/dev/null 2>&1; then
    echo "[deploy] ERROR: '${cmd}' is not installed or not in PATH"
    exit 1
  fi
done

# Optionally ensure kubectl context is pointing to the desired cluster
CURRENT_CONTEXT="$(kubectl config current-context || true)"
echo "[deploy] Current kubectl context: ${CURRENT_CONTEXT}"

# Apply manifests in the correct order
echo "[deploy] Applying namespace..."
kubectl apply -f k8s/namespace.yaml

echo "[deploy] Applying ConfigMap..."
kubectl apply -f k8s/configmap.yaml

echo "[deploy] Applying Secret..."
kubectl apply -f k8s/secret.yaml

echo "[deploy] Applying Deployment..."
kubectl apply -f k8s/deployment.yaml

echo "[deploy] Applying Service..."
kubectl apply -f k8s/service.yaml

echo "[deploy] Applying HorizontalPodAutoscaler..."
kubectl apply -f k8s/hpa.yaml

# Wait for Deployment rollout to complete
echo "[deploy] Waiting for Deployment rollout to complete..."
kubectl rollout status deployment/webapp-deployment -n "${NAMESPACE}"

echo "[deploy] Deployment successfully rolled out."

# Retrieve LoadBalancer hostname
echo "[deploy] Fetching LoadBalancer hostname (this can take a few minutes)..."
# Wait until the LoadBalancer ingress is available
ATTEMPTS=30
SLEEP_SECONDS=10
LB_HOSTNAME=""

for i in $(seq 1 "${ATTEMPTS}"); do
  LB_HOSTNAME="$(kubectl get svc webapp-service -n "${NAMESPACE}" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  if [[ -n "${LB_HOSTNAME}" ]]; then
    break
  fi
  echo "[deploy] LoadBalancer not ready yet. Attempt ${i}/${ATTEMPTS}..."
  sleep "${SLEEP_SECONDS}"
done

if [[ -z "${LB_HOSTNAME}" ]]; then
  echo "[deploy] WARNING: LoadBalancer hostname is not available yet."
  echo "You can check it later with:"
  echo "  kubectl get svc webapp-service -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
  exit 0
fi

echo "[deploy] LoadBalancer is ready."
echo "[deploy] External URL:"
echo "  http://${LB_HOSTNAME}"
