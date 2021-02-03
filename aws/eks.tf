resource "aws_kms_key" "eks" {
  description = "Hex EKS Secret Encryption Key"
}

resource "aws_kms_alias" "eks" {
  name          = "alias/hex/eks"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_kms_key" "workers" {
  description = "Hex EKS Workers EBS Encryption Key"
}

resource "aws_kms_alias" "workers" {
  name          = "alias/hex/workers"
  target_key_id = aws_kms_key.workers.key_id
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "13.2.1"
  cluster_version = "1.18"
  cluster_name    = "hex"
  subnets         = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  manage_aws_auth                 = true
  enable_irsa                     = true

  map_users = [
    # {
    #   "groups"   = ["system:masters"]
    #   "userarn"  = "YOURARN"
    #   "username" = "YOURUSER"
    # }
  ]

  tags = {
    Name = "Hex"
  }

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  vpc_id = module.vpc.vpc_id

  worker_groups = [
    {
      name                 = "worker-group"
      instance_type        = "t3.large"
      asg_desired_capacity = 3
      root_kms_key_id      = aws_kms_key.workers.arn
      root_encrypted       = true
      tags = [{
        key                 = "hex-deployment"
        propagate_at_launch = true
        value               = "Hex"
      }]
    },
  ]
}
