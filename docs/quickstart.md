# Quickstart

Get a full EKS + ArgoCD GitOps platform running in about 30 minutes.
No prior knowledge of this repo is assumed — only AWS, Terraform, and
kubectl basics.

## Prerequisites

| Tool       | Version   | Check with              |
| ---------- | --------- | ----------------------- |
| AWS CLI    | v2        | `aws --version`         |
| Terraform  | >= 1.5.0  | `terraform version`     |
| kubectl    | >= 1.28   | `kubectl version`       |
| Helm       | v3        | `helm version`          |
| Docker     | any recent| `docker --version`      |

You also need:

- An AWS account with permissions to create VPCs, EKS clusters, and IAM roles.
- AWS credentials configured (`aws configure` or environment variables).
- A GitHub account if you want to push the demo app image to GHCR
  (or use any container registry — see `docs/customization.md`).

## Step 1 — Clone and configure

```bash
git clone https://github.com/XEESHANAKRAM/eks-gitops-starter.git
cd eks-gitops-starter
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars if you want a different region or cluster size.
```

## Step 2 — Run the bootstrap script

```bash
./scripts/bootstrap.sh
```

This does, in order:

1. `terraform apply` — VPC, EKS cluster, managed node group, add-ons, IAM roles.
2. `aws eks update-kubeconfig` — points kubectl at the new cluster.
3. Builds and pushes the demo app image to GHCR
   (needs `docker login ghcr.io` first; if Docker is missing it prints the
   commands to run instead).
4. Installs ArgoCD and kube-prometheus-stack with Helm.
5. Applies the namespaces, the ArgoCD ApplicationSet, the alert rules,
   and the Grafana dashboard.

**Expected result:** the script ends with a "Done" block listing the
ArgoCD, Grafana, and demo app URLs. `terraform apply` takes roughly
15–20 minutes (most of it is the EKS control plane).

## Step 3 — Check the demo app

```bash
kubectl get pods -n apps
# NAME                        READY   STATUS    RESTARTS   AGE
# demo-app-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
# demo-app-xxxxxxxxxx-xxxxx   1/1     Running   0          2m

kubectl port-forward svc/demo-app -n apps 8081:80
curl http://localhost:8081/
# {"app":"demo-app","message":"Hello from eks-gitops-starter!","gitops":"Deployed by ArgoCD from apps/demo-app/k8s"}
```

## Step 4 — See it in ArgoCD

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# open https://localhost:8080 — user: admin
# password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

You should see the `demo-app` application **Synced** and **Healthy**.

## Step 5 — See it in Grafana

```bash
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
# open http://localhost:3000 — user: admin
# password:
kubectl -n monitoring get secret prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

Open the **Demo App** dashboard: request rate, p95 latency, pod CPU/memory.

## Step 6 — Prove GitOps works

Change one line and watch ArgoCD sync it — no kubectl needed:

```bash
# Edit apps/demo-app/app.py, change the greeting message, commit, push.
# Then:
kubectl -n argocd get application demo-app -w
# Within a minute the app is Synced again, and the new message is live.
```

Note: changing the Python code requires rebuilding the image and updating
the tag in `apps/demo-app/k8s/deployment.yaml` (or use the image updater
pattern in `docs/customization.md`). Changing the manifests alone — e.g.
the replica count — syncs with no image rebuild.

## Tear down

```bash
./scripts/destroy.sh
```

See `docs/cost.md` before you leave it running, and `docs/troubleshooting.md`
if any step above does not produce the expected result.
