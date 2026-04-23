#!/usr/bin/env bash
# Build and push the Docker image to AWS ECR

set -euo pipefail

AWS_ACCOUNT_ID="<AWS_ACCOUNT_ID>"
AWS_REGION="us-east-1"
ECR_REPO_NAME="eks-webapp"
IMAGE_TAG="${1:-latest}"

ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE="${ECR_URI}/${ECR_REPO_NAME}:${IMAGE_TAG}"

echo "[build-push] Building and pushing image: ${IMAGE}"

# Check required commands
for cmd in aws docker; do
  if ! command -t "${cmd}" >/dev/null 2>&1; then
    echo "[build-push] ERROR: '${cmd}' is not installed or not in PATH"
    exit 1
  fi
done

# Ensure AWS_REGION is set for AWS CLI
export AWS_REGION

echo "[build-push] Logging in to Amazon ECR..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_URI}"

# Create ECR repository if it doesn't exist
echo "[build-push] Ensuring ECR repository '${ECR_REPO_NAME}' exists..."
if ! aws ecr describe-repositories --repository-names "${ECR_REPO_NAME}" >/dev/null 2>&1; then
  echo "[build-push] Repository not found. Creating..."
  aws ecr create-repository --repository-name "${ECR_REPO_NAME}" >/dev/null
  echo "[build-push] Repository '${ECR_REPO_NAME}' created."
else
  echo "[build-push] Repository '${ECR_REPO_NAME}' already exists."
fi

echo "[build-push] Building Docker image..."
docker build -t "${IMAGE}" .

echo "[build-push] Pushing Docker image to ECR..."
docker push "${IMAGE}"

echo "[build-push] Image pushed successfully: ${IMAGE}"
