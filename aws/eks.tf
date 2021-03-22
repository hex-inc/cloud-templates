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

resource "aws_iam_user" "eks-user" {
  force_destroy = "false"
  name          = "${var.name}-eks-user"
  path          = "/"
}

resource "aws_iam_access_key" "eks-user" {
  user = aws_iam_user.eks-user.name
}

resource "aws_iam_access_key" "eks-user-test" {
  user    = aws_iam_user.eks-user.name
  pgp_key = "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"
}

resource "aws_iam_policy" "eks-user" {
  description = "Allow user to use EKS clusters"
  name        = "eks-user"
  policy      = data.aws_iam_policy_document.eks-user.json
}

resource "aws_iam_user_policy_attachment" "eks-user" {
  user       = aws_iam_user.eks-user.name
  policy_arn = aws_iam_policy.eks-user.arn
}

data "aws_iam_policy_document" "eks-user" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:AccessKubernetesApi",
      "ssm:GetParameter",
      "eks:ListUpdates",
      "eks:ListFargateProfiles",
    ]
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 13.2"
  cluster_version = "1.18"
  cluster_name    = var.name
  subnets         = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  manage_aws_auth                 = true
  enable_irsa                     = true

  map_users = [
    {
      "groups"   = ["system:masters"]
      "userarn"  = aws_iam_user.eks-user.arn
      "username" = "${var.name}-eks-user"
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

  vpc_id = module.vpc.vpc_id

  worker_groups = [
    {
      name                 = "worker-group"
      instance_type        = var.instance_type
      asg_desired_capacity = var.num_nodes
      root_kms_key_id      = aws_kms_key.workers.arn
      root_encrypted       = true
    },
  ]
}

// Needed for managing auth
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
