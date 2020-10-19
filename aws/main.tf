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
  source = "./modules/s3"
  name   = var.name
}

module "rds" {
  source                = "./modules/rds"
  name                  = var.name
  vpc_id                = module.vpc.vpc_id
  security_groups       = [module.eks.worker_security_group_id]
  database_subnet_group = module.vpc.database_subnet_group
}

module "alb" {
  source  = "./modules/alb"
  region  = var.region
  cluster = data.aws_eks_cluster.cluster.name
}

module "calico" {
  source = "./modules/calico"
}
