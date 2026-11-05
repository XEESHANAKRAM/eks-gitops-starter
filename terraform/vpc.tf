# VPC with public and private subnets across 3 AZs.
# Worker nodes live in private subnets; the load balancer lives in public subnets.
#
# Flow Logs are enabled (enable_flow_log = true, CloudWatch Logs destination,
# log group + IAM role created by the module). tfsec cannot trace them: the
# module passes the VPC id to aws_flow_log through local.vpc_id, a try()
# expression, which tfsec's resolver does not follow.
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs to CloudWatch Logs (tfsec check aws-ec2-require-vpc-flow-logs-for-all-vpcs).
  enable_flow_log = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}
