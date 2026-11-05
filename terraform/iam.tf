# IAM roles used by the platform.
#
# 1. ebs_csi — IRSA role for the EBS CSI driver add-on (referenced by
#    cluster_addons in eks.tf). Lets pods provision PersistentVolumes.
# 2. argocd — IRSA role for ArgoCD Image Updater. Optional: only used if you
#    install ArgoCD Image Updater and store images in a private ECR
#    repository. ArgoCD itself needs no AWS role; it talks to the cluster
#    API through its in-cluster service account.
# 3. github_actions_ci — OIDC role for GitHub Actions. Read-only on purpose:
#    CI runs `terraform plan` only. `terraform apply` is a deliberate manual
#    step, run locally by a human. See .github/workflows/ci.yml.

# ---------------------------------------------------------------------------
# 1. EBS CSI driver (IRSA)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "ebs_csi_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${local.name}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ---------------------------------------------------------------------------
# 2. ArgoCD Image Updater (IRSA, optional)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "argocd_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:argocd:argocd-image-updater"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "argocd" {
  name               = "${local.name}-argocd"
  assume_role_policy = data.aws_iam_policy_document.argocd_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "argocd_ecr_read" {
  role       = aws_iam_role.argocd.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ---------------------------------------------------------------------------
# 3. GitHub Actions OIDC (CI: terraform plan only)
# ---------------------------------------------------------------------------
data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
  tags            = local.tags
}

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Read-only permissions: enough for `terraform plan` and the security scans.
# Deliberately NOT enough for `terraform apply`.
data "aws_iam_policy_document" "github_actions_ci_readonly" {
  statement {
    sid    = "ReadOnlyForTerraformPlan"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:Get*",
      "eks:Describe*",
      "eks:List*",
      "iam:Get*",
      "iam:List*",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "github_actions_ci" {
  name               = "${local.name}-github-actions-ci"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "github_actions_ci_readonly" {
  name   = "terraform-plan-readonly"
  role   = aws_iam_role.github_actions_ci.id
  policy = data.aws_iam_policy_document.github_actions_ci_readonly.json
}
