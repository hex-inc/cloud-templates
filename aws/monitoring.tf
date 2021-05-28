locals {
  prometheus_name = "${var.name}-prometheus"
  vault_endpoint  = "hex-vault.${helm_release.hex.namespace}:8200"
}

resource "kubernetes_namespace" "monitoring" {
  count = var.monitoring_enabled ? 1 : 0
  metadata {
    name = "monitoring"
  }
}

data "kubernetes_secret" "hex_vault_keys" {
  count = var.monitoring_enabled ? 1 : 0
  metadata {
    name      = "hex-vault-keys"
    namespace = "hex"
  }
}

resource "kubernetes_secret" "hex_vault_keys" {
  count = var.monitoring_enabled ? 1 : 0
  metadata {
    name      = "hex-vault-keys"
    namespace = "monitoring"
  }
  data = data.kubernetes_secret.hex_vault_keys[count.index].data
}

resource "helm_release" "newrelic" {
  count      = var.monitoring_enabled ? 1 : 0
  name       = "${var.name}-nr"
  namespace  = "monitoring"
  repository = "https://helm-charts.newrelic.com"
  chart      = "nri-bundle"
  version    = "2.2.1"

  values = [
    file("helm_values/newrelic.yaml")
  ]

  set {
    name  = "global.cluster"
    value = rancher2_cluster.hex.name
  }
  set_sensitive {
    name  = "global.licenseKey"
    value = var.newrelic_license_key
  }
}

resource "helm_release" "prometheus" {
  count      = var.monitoring_enabled ? 1 : 0
  name       = "prometheus"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "13.2.1"

  values = [
    templatefile("helm_values/prometheus.yaml.tpl", { vault-endpoint : local.vault_endpoint, nr-license-key : var.newrelic_license_key, name : local.prometheus_name }),
  ]
}

resource "newrelic_alert_channel" "slack" {
  count = var.monitoring_enabled ? 1 : 0
  name  = "${var.name}-slack"
  type  = "slack"

  config {
    url = var.nr_slack_webhook
  }
}


resource "newrelic_alert_policy" "default" {
  count               = var.monitoring_enabled ? 1 : 0
  name                = var.name
  incident_preference = "PER_CONDITION_AND_TARGET"
}

resource "newrelic_alert_policy_channel" "default" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id
  channel_ids = [
    newrelic_alert_channel.slack[count.index].id
  ]
}
