module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = "tech-challenge-vpc"
  cidr = var.vpc_cidr

  azs             = ["eu-central-1a","eu-central-1b","eu-central-1c"]
  public_subnets  = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24","10.0.12.0/24","10.0.13.0/24"]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 22.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  subnets = module.vpc.private_subnets

  node_groups = {
    ng1 = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Project = "tech-challenge"
  }
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_name" {
  value = module.eks.cluster_id
}
