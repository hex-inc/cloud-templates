resource "aws_kms_key" "eks" {
  description = "EKS Secret Encryption Key"

  tags = {
    "hex-deployment" = local.name
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.name}/eks"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_kms_key" "workers" {
  description = "EKS Workers EBS Encryption Key"

  tags = {
    "hex-deployment" = local.name
  }
}

resource "aws_kms_alias" "workers" {
  name          = "alias/${local.name}/workers"
  target_key_id = aws_kms_key.workers.key_id
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  version      = "12.2.0"
  cluster_name = local.name
  subnets      = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  manage_aws_auth                 = true
  enable_irsa                     = true

  tags = {
    Name             = local.name
    "hex-deployment" = local.name
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
      instance_type        = var.instance_type
      asg_desired_capacity = var.num_nodes
      root_kms_key_id      = aws_kms_key.workers.arn
      root_encrypted       = true
      tags = [{
        key                 = "hex-deployment"
        propagate_at_launch = true
        value               = local.name
      }]
    },
  ]
}
