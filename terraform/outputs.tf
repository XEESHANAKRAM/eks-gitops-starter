output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster API server."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate data for the cluster."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (worker nodes)."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (load balancers)."
  value       = module.vpc.public_subnets
}

output "oidc_provider_arn" {
  description = "ARN of the cluster OIDC provider (used by IRSA roles)."
  value       = module.eks.oidc_provider_arn
}

output "ebs_csi_role_arn" {
  description = "ARN of the IAM role used by the EBS CSI driver."
  value       = aws_iam_role.ebs_csi.arn
}

output "argocd_role_arn" {
  description = "ARN of the optional IRSA role for ArgoCD Image Updater."
  value       = aws_iam_role.argocd.arn
}

output "github_actions_role_arn" {
  description = "ARN of the OIDC role GitHub Actions assumes for terraform plan. Set it as the AWS_ROLE_TO_ASSUME repository variable."
  value       = aws_iam_role.github_actions_ci.arn
}
