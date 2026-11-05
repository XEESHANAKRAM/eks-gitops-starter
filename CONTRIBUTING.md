# Contributing to eks-gitops-starter

Thanks for considering a contribution. This is a small, focused starter
project, so the bar is simple: keep it working, keep it honest, keep it
small.

## How to contribute

1. Fork the repo and create a branch from `main`.
2. Make your change. If it touches infrastructure, run the checks below.
3. Open a pull request with a short description of what changed and why.
   Include the output of the checks if you ran them against a real cluster.

## Checks (run before opening a PR)

```bash
# Terraform formatting + validation
cd terraform
terraform fmt -check -diff -recursive
terraform init -backend=false
terraform validate

# YAML lint
yamllint .

# Demo app image
docker build -t demo-app:dev apps/demo-app
```

CI runs the same checks on every pull request, plus tfsec and a Trivy
image scan.

## Ground rules

- **No fake claims.** Do not add claims about users, stars, downloads,
  production deployments, or certifications that do not exist. This repo
  is a starter/boilerplate — describe it as one.
- **Security first.** No hardcoded secrets, passwords, or tokens anywhere.
  Use the patterns in `docs/security.md`.
- **Keep the quickstart working.** If your change breaks
  `docs/quickstart.md`, update the docs in the same PR.
- **Small PRs.** One change per PR where possible; big refactors should be
  discussed in an issue first.
