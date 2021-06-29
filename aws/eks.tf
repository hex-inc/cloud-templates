resource "aws_kms_key" "eks" {
  description = "${var.name} EKS Secret Encryption Key"
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.name}/eks"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_kms_key" "workers" {
  description = "${var.name} EKS Workers EBS Encryption Key"
}

resource "aws_kms_alias" "workers" {
  name          = "alias/${var.name}/workers"
  target_key_id = aws_kms_key.workers.key_id
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 13.2"
  cluster_version = "1.18"
  cluster_name    = var.name
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  cluster_endpoint_private_access = true
  manage_aws_auth                 = true
  enable_irsa                     = true

  map_users = [for user in aws_iam_user.eks-user :
    {
      "groups"   = ["system:masters"]
      "userarn"  = user.arn
      "username" = user.name
    }
  ]

  tags = {
    Name = var.name
  }

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  worker_groups = [
    {
      name                 = "worker-group"
      instance_type        = var.instance_type
      asg_max_size         = var.num_nodes
      asg_min_size         = var.num_nodes
      asg_desired_capacity = var.num_nodes
      root_kms_key_id      = aws_kms_key.workers.arn
      root_encrypted       = true
    },
  ]
}
