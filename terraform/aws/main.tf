module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = "tech-challenge-vpc"
  cidr = var.vpc_cidr

  enable_nat_gateway = true
  enable_vpn_gateway = true
  single_nat_gateway = false

  azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "eks-cluster"
  kubernetes_version = "1.33"

  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id
}
