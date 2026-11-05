#!/usr/bin/env bash
# Bootstrap the full platform: Terraform infra -> ArgoCD -> monitoring -> demo app.
# Run from the repo root: ./scripts/bootstrap.sh
# Prerequisites: aws, terraform, kubectl, helm, docker (optional, for the demo image).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-eks-gitops-starter}"
AWS_REGION="${AWS_REGION:-us-east-1}"
IMAGE="${IMAGE:-ghcr.io/xeeshanakram/demo-app:0.1.0}"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: $1 is not installed." >&2; exit 1; }
}

need aws
need terraform
need kubectl
need helm

echo "==> 1/5 Terraform: creating VPC + EKS cluster"
cd "$ROOT/terraform"
terraform init
terraform apply -auto-approve \
  -var "cluster_name=$CLUSTER_NAME" \
  -var "aws_region=$AWS_REGION"

echo "==> 2/5 kubeconfig"
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"

echo "==> 3/5 Demo app image"
if command -v docker >/dev/null 2>&1; then
  echo "Building and pushing $IMAGE (requires 'docker login ghcr.io' first)"
  docker build -t "$IMAGE" "$ROOT/apps/demo-app"
  docker push "$IMAGE"
else
  echo "WARNING: docker not found. Build and push the image yourself, or the"
  echo "demo app pods will stay in ImagePullBackOff until you do:"
  echo "  docker build -t $IMAGE $ROOT/apps/demo-app"
  echo "  docker push $IMAGE"
fi

echo "==> 4/5 ArgoCD + monitoring (Helm)"
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo update >/dev/null

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --values "$ROOT/kubernetes/argocd/values.yaml" \
  --wait

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --values "$ROOT/kubernetes/monitoring/values.yaml" \
  --wait

echo "==> 5/5 GitOps: namespaces, ArgoCD apps, alert rules, dashboard"
kubectl apply -k "$ROOT/kubernetes/argocd"
kubectl apply -k "$ROOT/kubernetes/monitoring"

echo "==> Waiting for the demo app to become healthy"
kubectl wait --namespace apps --for=condition=available deployment/demo-app --timeout=300s

echo
echo "Done. Next steps:"
echo "  ArgoCD UI:  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "              user: admin"
echo "              password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "  Grafana:    kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
echo "              user: admin"
echo "              password: kubectl -n monitoring get secret prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d"
echo "  Demo app:   kubectl port-forward svc/demo-app -n apps 8081:80"
echo "              then open http://localhost:8081"
