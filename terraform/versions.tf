terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state is recommended for teams. Uncomment and fill in your
  # bucket/table, then run `terraform init -reconfigure`.
  # backend "s3" {
  #   bucket         = "eks-gitops-starter-tfstate"
  #   key            = "eks-gitops-starter/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "eks-gitops-starter-tfstate-lock"
  #   encrypt        = true
  # }
}
