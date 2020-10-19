module "eks-calico" {
  source  = "lablabs/eks-calico/aws"
  version = "0.2.0"

  enabled = true
}
