# How to Run — Visual Guide

Run the whole platform end to end: Terraform builds the AWS
infrastructure, ArgoCD deploys the demo app from Git, and Prometheus +
Grafana watch it. Every step below shows the command and the output you
should expect.

> **Read this first — what is real and what is not.**
>
> - This repo has **never been deployed to AWS**. Every block labelled
>   **"Expected output"** is **illustrative**: it shows the shape of the
>   output you should see on a real run, based on the repo's own scripts,
>   manifests, and the tools' normal output formats. Exact names, hashes,
>   counts, and versions will differ on your run.
> - The **only real output in this guide** is the section
>   [Real local run of the demo app](#real-local-run-of-the-demo-app),
>   which was actually run in this sandbox on 2026-11-05. That section
>   proves the app code works — it does **not** prove the EKS deployment
>   works.
> - Architecture diagram:
>   [`docs/screenshots/architecture.svg`](screenshots/architecture.svg)
>   (also in [`docs/architecture.md`](architecture.md)).
> - Short version of this guide: [`docs/quickstart.md`](quickstart.md).
>   Costs: [`docs/cost.md`](cost.md) (~$180–195/month, us-east-1).
>   If a step fails: [`docs/troubleshooting.md`](troubleshooting.md).

## Prerequisites

| Tool      | Version   | Check with          |
| --------- | --------- | ------------------- |
| AWS CLI   | v2        | `aws --version`     |
| Terraform | >= 1.5.0  | `terraform version` |
| kubectl   | >= 1.28   | `kubectl version`   |
| Helm      | v3        | `helm version`      |
| Docker    | any recent| `docker --version`  |

You also need an AWS account with permissions to create VPCs, EKS
clusters, and IAM roles, and AWS credentials configured
(`aws configure` or environment variables). Docker is only needed to
build the demo app image — if it is missing, `bootstrap.sh` prints the
commands to run instead.

## Step 1 — Clone and configure

```bash
git clone https://github.com/XEESHANAKRAM/eks-gitops-starter.git
cd eks-gitops-starter
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars if you want a different region or cluster size.
# Defaults: region us-east-1, cluster eks-gitops-starter, 2× t3.medium.
```

**Expected output (illustrative — not from a live run):**

```text
Cloning into 'eks-gitops-starter'...
```

## Step 2 — Run the bootstrap script

```bash
./scripts/bootstrap.sh
```

This runs five stages in order (see
[`scripts/bootstrap.sh`](../scripts/bootstrap.sh)):

1. `terraform apply` — VPC, EKS cluster, managed node group, add-ons, IAM roles.
2. `aws eks update-kubeconfig` — points kubectl at the new cluster.
3. Builds and pushes the demo app image to GHCR
   (`ghcr.io/xeeshanakram/demo-app:0.1.0`; needs `docker login ghcr.io` first).
4. Installs ArgoCD and kube-prometheus-stack with Helm.
5. Applies the namespaces, the ArgoCD ApplicationSet, the alert rules,
   and the Grafana dashboard — then waits for the demo app to be healthy.

Takes ~30 minutes, mostly the EKS control plane (`terraform apply`
alone is roughly 15–20 minutes).

**Expected output (illustrative — not from a live run):**

```text
==> 1/5 Terraform: creating VPC + EKS cluster
...
Apply complete! Resources: N added, 0 changed, 0 destroyed.
==> 2/5 kubeconfig
Added new context arn:aws:eks:us-east-1:<account>:cluster/eks-gitops-starter to ~/.kube/config
==> 3/5 Demo app image
Building and pushing ghcr.io/xeeshanakram/demo-app:0.1.0 ...
==> 4/5 ArgoCD + monitoring (Helm)
...
==> 5/5 GitOps: namespaces, ArgoCD apps, alert rules, dashboard
...
==> Waiting for the demo app to become healthy
deployment.apps/demo-app condition met

Done. Next steps:
  ArgoCD UI:  kubectl port-forward svc/argocd-server -n argocd 8080:443
              user: admin
              password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
  Grafana:    kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
              user: admin
              password: kubectl -n monitoring get secret prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d
  Demo app:   kubectl port-forward svc/demo-app -n apps 8081:80
              then open http://localhost:8081
```

(The `Done` block is quoted from the script itself; the exact number of
resources and the timing lines will differ on your run.)

## Step 3 — Or run Terraform by hand

If you prefer to run Terraform yourself instead of `bootstrap.sh`:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Expected output (illustrative — not from a live run):**

```text
$ terraform init
Initializing the backend...
Initializing modules...
...
Terraform has been successfully initialized!

$ terraform plan
...
Plan: N to add, 0 to change, 0 to destroy.

$ terraform apply
...
Apply complete! Resources: N added, 0 changed, 0 destroyed.
```

(`N` depends on the module versions — the line to look for is
`Apply complete!`. Then point kubectl at the cluster:
`aws eks update-kubeconfig --name eks-gitops-starter --region us-east-1`.)

## Step 4 — Verify the cluster

```bash
kubectl get nodes
kubectl get pods -n apps
kubectl get pods -n argocd
kubectl get pods -n monitoring
```

**Expected output (illustrative — not from a live run):**

```text
$ kubectl get nodes
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-123.us-east-1.compute.internal      Ready    <none>   5m    v1.31.3
ip-10-0-2-45.us-east-1.compute.internal       Ready    <none>   5m    v1.31.3

$ kubectl get pods -n apps
NAME                        READY   STATUS    RESTARTS   AGE
demo-app-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
demo-app-xxxxxxxxxx-xxxxx   1/1     Running   0          2m

$ kubectl get pods -n argocd
NAME                                          READY   STATUS    RESTARTS   AGE
argocd-server-xxxxxxxxxx-xxxxx                1/1     Running   0          3m
argocd-repo-server-xxxxxxxxxx-xxxxx           1/1     Running   0          3m
argocd-application-controller-0               1/1     Running   0          3m
argocd-applicationset-controller-xxxxxxxxxx   1/1     Running   0          3m
argocd-redis-xxxxxxxxxx-xxxxx                 1/1     Running   0          3m

$ kubectl get pods -n monitoring
NAME                                              READY   STATUS    RESTARTS   AGE
prometheus-grafana-xxxxxxxxxx-xxxxx               2/2     Running   0          3m
prometheus-kube-prometheus-prometheus-0           2/2     Running   0          3m
prometheus-kube-state-metrics-xxxxxxxxxx-xxxxx    1/1     Running   0          3m
prometheus-prometheus-node-exporter-xxxxx         1/1     Running   0          3m
prometheus-prometheus-node-exporter-xxxxx         1/1     Running   0          3m
```

(Pod names and hashes will differ. What matters: every pod is
`Running` and `READY` shows `1/1` or `2/2` — no `CrashLoopBackOff`,
no `ImagePullBackOff`.)

## Step 5 — See it in ArgoCD

Port-forward the ArgoCD UI and log in:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# open https://localhost:8080 — user: admin
# password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

You should see the `demo-app` application **Synced** and **Healthy**.

Or use the ArgoCD CLI (install it from
https://argo-cd.readthedocs.io/en/stable/cli_installation/):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
argocd login localhost:8080 --username admin \
  --password "$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d)" --insecure
argocd app list
```

**Expected output (illustrative — not from a live run):**

```text
$ argocd app list
NAME      CLUSTER                         NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS
demo-app  https://kubernetes.default.svc  apps       default  Synced  Healthy  Auto-Prune  <none>
```

Or without the CLI:

```bash
kubectl -n argocd get application demo-app
```

**Expected output (illustrative — not from a live run):**

```text
NAME       SYNC STATUS   HEALTH STATUS
demo-app   Synced        Healthy
```

## Step 6 — Hit the demo app

```bash
kubectl port-forward svc/demo-app -n apps 8081:80
curl http://localhost:8081/
curl http://localhost:8081/healthz
```

**Expected output (illustrative — not from a live run):**

```text
$ curl http://localhost:8081/
{"app":"demo-app","gitops":"Deployed by ArgoCD from apps/demo-app/k8s","message":"Hello from eks-gitops-starter!"}

$ curl http://localhost:8081/healthz
{"status":"ok"}
```

(This is the same JSON the app returns in the
[real local run](#real-local-run-of-the-demo-app) below — same code,
same endpoints, only the place it runs differs.)

## Step 7 — Open the Grafana dashboard

```bash
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
# open http://localhost:3000 — user: admin
# password:
kubectl -n monitoring get secret prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

Open the **Demo App** dashboard. It has four panels, fed by the
ServiceMonitor that scrapes the app's `/metrics` endpoint:

| Panel | What it shows |
| ----- | ------------- |
| Requests / sec | `demo_app_http_requests_total` rate |
| p95 latency | `demo_app_http_request_duration_seconds` |
| Pod CPU | demo-app container CPU usage |
| Pod memory | demo-app container memory usage |

Generate some traffic first (`curl http://localhost:8081/` a few
times, as in Step 6) so the panels have data to show.

> No screenshot of this dashboard exists yet — the repo has never been
> deployed to AWS. The screenshots that will be added after the first
> real deployment are listed in
> [`docs/screenshots/README.md`](screenshots/README.md).

## Step 8 — Prove GitOps works

Change one line and watch ArgoCD sync it — no kubectl needed:

```bash
# Edit apps/demo-app/k8s/deployment.yaml — change replicas: 2 to replicas: 3.
# Commit and push.
kubectl -n argocd get application demo-app -w
```

**Expected output (illustrative — not from a live run):**

```text
NAME       SYNC STATUS   HEALTH STATUS
demo-app   OutOfSync     Healthy
demo-app   Synced        Healthy
```

Then check the pods — there should be three:

```bash
kubectl get pods -n apps
```

Note: changing the Python code needs an image rebuild and a tag bump
in `apps/demo-app/k8s/deployment.yaml` (or the image updater pattern
in [`docs/customization.md`](customization.md)). Changing the
manifests alone — e.g. the replica count — syncs with no image rebuild.

## Step 9 — Tear down

```bash
./scripts/destroy.sh
```

**Expected output (illustrative — not from a live run):**

```text
Destroy complete! Resources: N destroyed.
```

Check [`docs/cost.md`](cost.md) before you leave the cluster running:
the default setup is ~$180–195/month in `us-east-1`, and it keeps
charging while it exists.

## Real local run of the demo app

> **This section is real output — not the EKS deployment.** The app was
> run on this sandbox (Python 3.12.3, Flask 3.0.3, gunicorn 22.0.0,
> prometheus-client 0.20.0) on 2026-11-05, exactly the way the
> Dockerfile runs it (gunicorn, 2 workers, port 8080). It proves the
> app code works. It does not prove the EKS deployment works.

Commands run:

```bash
python3 -m venv /tmp/demo-venv
/tmp/demo-venv/bin/pip install -r apps/demo-app/requirements.txt
cd apps/demo-app
/tmp/demo-venv/bin/gunicorn --bind 127.0.0.1:8080 --workers 2 app:app
```

Real server log:

```text
[2026-11-05 09:34:11 +0000] [6316] [INFO] Starting gunicorn 22.0.0
[2026-11-05 09:34:11 +0000] [6316] [INFO] Listening at: http://127.0.0.1:8080 (6316)
[2026-11-05 09:34:11 +0000] [6316] [INFO] Using worker: sync
[2026-11-05 09:34:11 +0000] [6318] [INFO] Booting worker with pid: 6318
[2026-11-05 09:34:11 +0000] [6319] [INFO] Booting worker with pid: 6319
```

Real `curl` output:

```text
$ curl -s http://127.0.0.1:8080/
{"app":"demo-app","gitops":"Deployed by ArgoCD from apps/demo-app/k8s","message":"Hello from eks-gitops-starter!"}
HTTP 200

$ curl -s http://127.0.0.1:8080/healthz
{"status":"ok"}
HTTP 200
```

Real `/metrics` output (excerpt — the full output also includes
`python_gc_*` and `process_*` series; the per-bucket histogram lines
are omitted here for brevity):

```text
$ curl -s http://127.0.0.1:8080/metrics | grep "^demo_app"
demo_app_http_requests_total{endpoint="/",method="GET",status="200"} 1.0
demo_app_http_requests_total{endpoint="/healthz",method="GET",status="200"} 1.0
demo_app_http_request_duration_seconds_count{endpoint="/",method="GET"} 1.0
demo_app_http_request_duration_seconds_sum{endpoint="/",method="GET"} 0.0001704692840576172
demo_app_http_request_duration_seconds_count{endpoint="/healthz",method="GET"} 1.0
demo_app_http_request_duration_seconds_sum{endpoint="/healthz",method="GET"} 0.00010514259338378906
```

(Each `curl` above incremented the counters — that is why each endpoint
shows exactly `1.0`. The `python_info` series in the same output
reports `version="3.12.3"`, matching the sandbox Python.)

You can reproduce this yourself without AWS or Docker, straight from
the repo:

```bash
pip install -r apps/demo-app/requirements.txt
python apps/demo-app/app.py
# open http://localhost:8080
```

## If a step does not work

See [`docs/troubleshooting.md`](troubleshooting.md) — it covers the
common failures (missing Docker, image pull errors, ArgoCD out of
sync, Grafana login, costs) with fixes. If you hit something new,
open an issue with the command you ran and the output you got.
