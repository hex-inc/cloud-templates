module "alb_controller" {
  source = "github.com/GSA/terraform-kubernetes-aws-load-balancer-controller"

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"

  aws_region_name           = data.aws_region.current.name
  k8s_cluster_name          = module.eks.cluster_id
  alb_controller_depends_on = [module.eks]
}