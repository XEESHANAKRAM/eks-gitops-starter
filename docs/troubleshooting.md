# Troubleshooting

## `terraform apply` fails with access errors

**Symptom:** `AccessDenied` / `UnauthorizedOperation` during apply.

**Fix:** the AWS credentials in use need permission to create VPCs, EKS
clusters, and IAM roles. If you use an IAM user, attach
`AdministratorAccess` for the first run (narrow it afterwards), or use
an admin role. Verify with:

```bash
aws sts get-caller-identity
```

## `terraform validate` fails on `module.eks`

**Symptom:** `Error: Missing required argument` or a module download error.

**Fix:** run `terraform init` first — the modules are downloaded from the
Terraform Registry. If you are offline, validation cannot download the
modules; the code itself is still valid.

## Demo app pods stuck in `ImagePullBackOff`

**Symptom:**

```bash
kubectl get pods -n apps
# demo-app-xxx   0/1   ImagePullBackOff
```

**Fix:** the image `ghcr.io/xeeshanakram/demo-app:0.1.0` has not been
pushed yet, or the registry is private. Build and push it (see
`apps/demo-app/README.md`), or point `deployment.yaml` at your own
registry and commit.

## ArgoCD shows the app `OutOfSync`

**Symptom:** the `demo-app` application is OutOfSync in the ArgoCD UI.

**Fix:** check what drifted:

```bash
kubectl -n argocd get application demo-app -o yaml | grep -A 20 status
```

Common cause: someone edited a resource by hand. ArgoCD self-heals
within a minute (automated sync + selfHeal are on). If the diff is your
own uncommitted change, commit it — Git is the source of truth.

## ArgoCD shows the app `Degraded`

**Symptom:** the application is Synced but Degraded, pods not Ready.

**Fix:** look at the pods:

```bash
kubectl -n apps describe pod -l app=demo-app
kubectl -n apps logs -l app=demo-app --tail=50
```

Usually this is the image problem above, or a failed readiness probe.

## Grafana login fails

**Symptom:** `admin` + the password from the secret does not log in.

**Fix:** make sure you read the secret from the right namespace and
release name:

```bash
kubectl -n monitoring get secret prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

If you changed the Helm release name, the secret name changes too.

## Prometheus has no demo-app metrics

**Symptom:** the "Demo App" dashboard panels are empty.

**Fix:** check the ServiceMonitor and the target:

```bash
kubectl -n monitoring get servicemonitor demo-app
kubectl -n monitoring get prometheusrule eks-gitops-starter-alerts
# In the Prometheus UI (port-forward svc/prometheus-operated 9090:9090),
# check Status -> Targets for the demo-app job.
```

The scrape only works once the demo app pods are Running and the
ServiceMonitor is in the `monitoring` namespace with the right labels.

## `kubectl` cannot reach the cluster

**Symptom:** `Unable to connect to the server` or `error: You must be
logged in to the server`.

**Fix:** regenerate the kubeconfig and check your AWS identity:

```bash
aws eks update-kubeconfig --name eks-gitops-starter --region us-east-1
aws sts get-caller-identity
```

Only the cluster creator (or an IAM principal granted access via an
access entry) can use the cluster.

## Destroy leaves a load balancer or volume behind

**Symptom:** after `./scripts/destroy.sh`, the AWS console still shows
a load balancer or EBS volume (and keeps charging).

**Fix:** delete it in the console (EC2 → Load Balancers, EC2 → Volumes)
or with the CLI, then re-run `terraform destroy`. This happens when a
Helm release was removed before its Service was deleted.
