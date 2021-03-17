locals {
  k8s_cluster_name = module.eks.cluster_id
}

data "aws_region" "current" {}

data "aws_eks_cluster" "target" {
  name = local.k8s_cluster_name
}

data "aws_eks_cluster_auth" "aws_iam_authenticator" {
  name = data.aws_eks_cluster.target.name
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.target.endpoint
  token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
  load_config_file       = false
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.target.endpoint
    token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
  }
}

module "alb_controller" {
  source = "github.com/GSA/terraform-kubernetes-aws-load-balancer-controller"

  providers = {
    kubernetes = "kubernetes.eks",
    helm       = "helm.eks"
  }

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  aws_region_name           = data.aws_region.current.name
  k8s_cluster_name          = data.aws_eks_cluster.target.name
  alb_controller_depends_on = [module.eks]
}