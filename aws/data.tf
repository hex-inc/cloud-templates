data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

data "aws_eks_cluster" "hex" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "hex" {
  name = module.eks.cluster_id
}
