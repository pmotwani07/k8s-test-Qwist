variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-cluster"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
