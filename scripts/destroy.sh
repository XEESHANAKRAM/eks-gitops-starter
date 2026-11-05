#!/usr/bin/env bash
# Destroy everything created by bootstrap.sh. This deletes the EKS cluster,
# the VPC, and all workloads. There is no undo.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-eks-gitops-starter}"
AWS_REGION="${AWS_REGION:-us-east-1}"

read -r -p "Destroy cluster '$CLUSTER_NAME' in $AWS_REGION and all its resources? (yes/no) " answer
if [ "$answer" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

# Remove Helm releases first so load balancers and PVCs are cleaned up
# before Terraform tears down the VPC.
helm uninstall prometheus --namespace monitoring 2>/dev/null || true
helm uninstall argocd --namespace argocd 2>/dev/null || true
kubectl delete namespace apps monitoring argocd --ignore-not-found 2>/dev/null || true

cd "$ROOT/terraform"
terraform destroy -auto-approve \
  -var "cluster_name=$CLUSTER_NAME" \
  -var "aws_region=$AWS_REGION"

echo "Destroyed. Check the AWS console for leftover load balancers or EBS volumes."
