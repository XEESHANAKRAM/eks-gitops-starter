# Screenshots

## What is here now

- [`architecture.svg`](architecture.svg) — hand-drawn architecture diagram
  of the platform this repo creates (GitHub → Terraform → AWS VPC + EKS,
  ArgoCD GitOps, Prometheus/Grafana). It matches the real Terraform,
  manifests, and scripts in this repo. Referenced from the README and
  [`docs/architecture.md`](../architecture.md).

## What is NOT here yet — real UI screenshots

This repo has **never been deployed to AWS**, so there are no real
screenshots of a live cluster yet. No screenshot in this folder is
faked, mocked, or drawn to look like a real UI. The following will be
added after the first real deployment (`./scripts/bootstrap.sh` on a
real AWS account), and this file will be updated when they land:

| # | File (planned) | What it will show | How to capture it |
| - | -------------- | ----------------- | ----------------- |
| 1 | `argocd-app-synced.png` | ArgoCD UI: the `demo-app` application **Synced** and **Healthy** | `kubectl port-forward svc/argocd-server -n argocd 8080:443`, open https://localhost:8080, log in as `admin`, screenshot the Applications list with `demo-app` visible |
| 2 | `grafana-demo-dashboard.png` | Grafana **Demo App** dashboard: requests/sec, p95 latency, pod CPU, pod memory, with real data | Generate traffic first (`curl http://localhost:8081/` a few times), then `kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80`, open http://localhost:3000, log in as `admin`, open the Demo App dashboard and screenshot it |
| 3 | `kubectl-get-pods.png` | Terminal: `kubectl get pods -n apps` showing both demo-app pods `1/1 Running` | Run `kubectl get pods -n apps` after bootstrap and screenshot the terminal (or paste the real output into the run guide) |

When a screenshot is added, the README and
[`docs/run-guide.md`](../run-guide.md) will link to it, and the
corresponding "Expected output" block in the run guide will be replaced
with (or joined by) the real capture.
