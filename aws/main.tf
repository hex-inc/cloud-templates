module "vpc" {
  source = "./modules/vpc"
  name   = var.name
}

module "eks" {
  source        = "./modules/eks"
  name          = var.name
  vpc_id        = module.vpc.vpc_id
  subnets       = module.vpc.private_subnets
  num_nodes     = var.num_nodes
  instance_type = var.instance_type
}

module "s3" {
  source      = "./modules/s3"
  name        = var.name
  bucket_name = "files"
}

module "cache-s3" {
  source      = "./modules/s3"
  name        = var.name
  bucket_name = "cache"
}

module "rds" {
  source                = "./modules/rds"
  name                  = var.name
  vpc_id                = module.vpc.vpc_id
  security_groups       = [module.eks.worker_security_group_id]
  database_subnet_group = module.vpc.database_subnet_group
}

module "alb" {
  source = "./modules/alb"

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  aws_region_name  = var.region
  k8s_cluster_name = data.aws_eks_cluster.cluster.name
}

module "calico" {
  source = "./modules/calico"

  enabled = true
}
