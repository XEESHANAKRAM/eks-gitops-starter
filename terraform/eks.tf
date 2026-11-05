# EKS cluster with one managed node group in the private subnets.
# Authentication uses EKS access entries (API mode) — no aws-auth ConfigMap.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access          = true
  enable_cluster_creator_admin_permissions = true

  # Modern auth: IAM principals get access via access entries, not the
  # aws-auth ConfigMap. See docs/security.md.
  # (In eks module v20.24+, aws-auth ConfigMap management was removed —
  # access entries are the only mechanism, so there is nothing to disable.)
  authentication_mode = "API"
  enable_irsa         = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Managed add-ons, kept in sync with the cluster version.
  # The EBS CSI driver uses the IRSA role created in iam.tf so pods can
  # provision PersistentVolumes.
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi.arn
    }
  }

  eks_managed_node_groups = {
    default = {
      name = "default"

      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Nodes run in private subnets and reach the internet via the NAT gateway.
      subnet_ids = module.vpc.private_subnets

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      tags = local.tags
    }
  }

  tags = local.tags
}
