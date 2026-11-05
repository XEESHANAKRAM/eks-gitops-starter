# Security

## What this repo does

- **No hardcoded secrets.** There are no passwords, tokens, or keys in
  this repo. ArgoCD and Grafana passwords are generated at install time
  and live in Kubernetes Secrets — retrieve them as shown in
  `docs/quickstart.md` and rotate them after first login.
- **Private subnets for nodes.** Worker nodes have no public IPs.
- **IRSA, not node-role permissions.** The EBS CSI driver and ArgoCD Image
  Updater use IAM Roles for Service Accounts scoped to one service
  account each (`terraform/iam.tf`). Pods do not inherit the node role.
- **API authentication mode.** Cluster access uses EKS access entries,
  not the `aws-auth` ConfigMap.
- **CI is read-only on AWS.** The GitHub OIDC role (`terraform/iam.tf`)
  only allows `Describe`/`Get`/`List` calls — enough for
  `terraform plan`, not for `terraform apply`. Applies run locally.
- **Scans in CI.** Every PR runs tfsec on the Terraform code and Trivy
  (HIGH/CRITICAL) on the demo app image.
- **Control plane logging + VPC Flow Logs on.** EKS API, audit,
  authenticator, controllerManager and scheduler logs, and VPC Flow Logs,
  all go to CloudWatch Logs (`terraform/eks.tf`, `terraform/vpc.tf`).
- **Public endpoint, restricted by variable.** The public EKS API
  endpoint stays on so the starter works with kubectl out of the box —
  no bastion needed. Restrict it with
  `cluster_endpoint_public_access_cidrs` (see below).

## Documented tfsec exceptions

Three findings are deliberately accepted and documented in the code with
`#tfsec:ignore` comments — they are starter trade-offs, not oversights:

- **Public cluster endpoint** (`terraform/eks.tf`): a starter must be
  usable with kubectl without a bastion or VPN. Restrict it with
  `cluster_endpoint_public_access_cidrs`.
- **Node security group egress to 0.0.0.0/0** (`terraform/eks.tf`): the
  rule is created by the terraform-aws-eks module, which exposes no input
  to change it. Nodes run in private subnets with no public IPs and reach
  the internet only through the NAT gateway.
- **VPC Flow Logs** (`terraform/vpc.tf`): Flow Logs ARE enabled
  (`enable_flow_log = true`, CloudWatch Logs destination). tfsec cannot
  see them because the terraform-aws-vpc module passes the VPC id to
  `aws_flow_log` through a `try()` local, which tfsec's resolver does not
  trace.
- **Wildcarded read-only IAM actions** (`terraform/iam.tf`): AWS does not
  support resource-level permissions for `ec2:Describe*`,
  `eks:Describe*`/`List*` and `iam:Get*`/`List*` — they require resource
  `*`. The role is read-only and only runs `terraform plan` in CI.
- **Non-root container.** The demo app image runs as user `appuser`,
  with CPU/memory limits and liveness + readiness probes.

## What you must do yourself

- **Rotate the generated passwords** after first login (ArgoCD admin,
  Grafana admin). The generated values are stored in Secrets, not in Git.
- **Enable the S3 backend** (`terraform/versions.tf`, commented out) for
  any shared or long-lived use — local state files contain sensitive
  values. Never commit `*.tfstate`.
- **Scope the CI role before using it for apply.** If you ever let CI
  apply, create a separate role with the exact permissions needed — do
  not widen the read-only role.
- **Use a secrets manager** (AWS Secrets Manager + External Secrets
  Operator, or Sealed Secrets) for real application secrets. Do not put
  secrets in ConfigMaps or manifests.
- **Keep versions current.** Bump the Kubernetes version, the EKS module,
  and the Helm charts regularly; the versions in this repo are a snapshot.
- **Restrict the API endpoint** for production: set
  `cluster_endpoint_public_access_cidrs` to your IP ranges (for example
  `["203.0.113.10/32"]`), or set `cluster_endpoint_public_access = false`
  in `terraform/eks.tf` and access the cluster through a bastion or VPN.
