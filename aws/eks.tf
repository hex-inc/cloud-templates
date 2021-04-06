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
      asg_max_size         = var.num_nodes
      asg_min_size         = var.num_nodes
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
