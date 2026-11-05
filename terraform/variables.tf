variable "project_name" {
  description = "Name used as a prefix for tags and resource names."
  type        = string
  default     = "eks-gitops-starter"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "eks-gitops-starter"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cheaper) instead of one per AZ. Set to false for production HA."
  type        = bool
  default     = true
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the CI deploy role, in owner/repo format."
  type        = string
  default     = "XEESHANAKRAM/eks-gitops-starter"
}

variable "tags" {
  description = "Extra tags applied to all resources."
  type        = map(string)
  default     = {}
}
