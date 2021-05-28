provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.hex.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.hex.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.hex.token
}

provider "helm" {
  // TODO: dedupe? with above?
  kubernetes {
    host                   = data.aws_eks_cluster.hex.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.hex.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.hex.token
  }
}

provider "newrelic" {
}
