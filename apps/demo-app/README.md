# Demo App

A tiny Flask web app that proves the GitOps flow end to end:

```
code change -> docker build -> git push -> ArgoCD sync -> running on EKS
```

It serves three endpoints:

| Endpoint   | What it does                                  |
| ---------- | --------------------------------------------- |
| `/`        | Returns a JSON greeting                       |
| `/healthz` | Liveness/readiness probe for Kubernetes       |
| `/metrics` | Prometheus metrics (request count + latency)  |

## Build the image

```bash
cd apps/demo-app
docker build -t ghcr.io/xeeshanakram/demo-app:0.1.0 .
docker push ghcr.io/xeeshanakram/demo-app:0.1.0
```

Then update `k8s/deployment.yaml` if your registry or tag differs, and
commit — ArgoCD picks it up automatically.

## Run it locally

```bash
pip install -r requirements.txt
python app.py
# open http://localhost:8080
```
