resource "helm_release" "kubernetes-dashboard" {
  name             = "kubernetes-dashboard"
  chart            = "kubernetes-dashboard"
  repository       = "https://kubernetes.github.io/dashboard/"
  version          = "4.0.0"
  namespace        = "kubernetes-dashboard"
  create_namespace = true

  set {
    name  = "metrics-server.enabled"
    value = "true"
  }
}
