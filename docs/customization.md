# Customization

## Change the region, size, or cluster version

Edit `terraform/terraform.tfvars` (copy from the `.example` file first):

```hcl
aws_region         = "eu-west-1"
kubernetes_version = "1.31"
node_instance_types = ["t3.large"]
node_desired_size   = 3
single_nat_gateway  = false   # one NAT gateway per AZ (production HA)
```

Then `terraform apply` from the `terraform/` directory.

## Add your own app (the GitOps way)

1. Add your manifests under `apps/<your-app>/k8s/` (with a
   `kustomization.yaml`, like the demo app).
2. Add one element to the list in
   `kubernetes/argocd/applications/demo-appset.yaml`:

```yaml
- app: my-app
  path: apps/my-app/k8s
  namespace: apps
```

3. Commit and push. ArgoCD creates the Application and syncs it — no
   `kubectl apply` needed.

## Expose the demo app publicly

1. Install an ingress controller, e.g. the AWS Load Balancer Controller.
2. Edit `apps/demo-app/k8s/ingress.yaml`: replace `demo.example.com`
   with your domain and set the `ingressClassName` to your controller's
   class.
3. Add `ingress.yaml` to `apps/demo-app/k8s/kustomization.yaml`
   (it is intentionally not listed by default).
4. Commit and push.

## Use a private ECR image with ArgoCD Image Updater

1. Install ArgoCD Image Updater.
2. Annotate its service account with the role created in Terraform:

```bash
kubectl -n argocd annotate sa argocd-image-updater \
  eks.amazonaws.com/role-arn=$(terraform -chdir=terraform output -raw argocd_role_arn)
```

3. Add the `argocd-image-updater.argoproj.io/image-list` annotation to
   your Application and let it track new tags.

## Change the demo app image

Build, push, and update the tag in `apps/demo-app/k8s/deployment.yaml`:

```bash
docker build -t ghcr.io/xeeshanakram/demo-app:0.2.0 apps/demo-app
docker push ghcr.io/xeeshanakram/demo-app:0.2.0
# edit k8s/deployment.yaml -> image: ghcr.io/xeeshanakram/demo-app:0.2.0
# commit + push -> ArgoCD syncs it
```
