provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "hex" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "hex" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.hex.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.hex.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.hex.token
  load_config_file       = false
}

provider "helm" {
  // TODO: dedupe? with above?
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    load_config_file       = false
  }
}
