resource "helm_release" "kubernetes-dashboard" {
  name       = "kubernetes-dashboard"
  chart      = "kubernetes-dashboard"
  repository = "https://kubernetes.github.io/dashboard/"
  version    = "4.0.0"

  set {
    name  = "metrics-server.enabled"
    value = "true"
  }

  set {
    name  = "fullnameOverride"
    value = "kubernetes-dashboard"
  }
}
