locals {
  signal_expiration_duration   = 300
  kernel_pools                 = toset(["${var.name}-prewarmed-kernels-private", "${var.name}-prewarmed-kernels-public"])
  statefulset_names            = toset(["${var.name}-builtinredis-slave", "${var.name}-builtinredis-master", "hex-vault"])
  deployment_names             = toset(["${var.name}-hex", "${var.name}-hex-data-service"])
  non_rolling_deployment_names = toset(["${var.name}-hex-data-service"]) #These deployments get sensitive alerts on podsMissing
}

# Node-level alerts
resource "newrelic_infra_alert_condition" "high_cpu_usage" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  name       = "High cpu usage in ${var.name}"
  type       = "infra_metric"
  event      = "K8sNodeSample"
  select     = "allocatableCpuCoresUtilization"
  comparison = "above"
  where      = "(clusterName = '${var.name}')"

  critical {
    duration      = 5
    value         = 90
    time_function = "all"
  }

  warning {
    duration      = 5
    value         = 70
    time_function = "all"
  }
}

resource "newrelic_infra_alert_condition" "high_disk_usage" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  name       = "High disk usage in ${var.name}"
  type       = "infra_metric"
  event      = "K8sNodeSample"
  select     = "fsCapacityUtilization"
  comparison = "above"
  where      = "(clusterName = '${var.name}')"

  critical {
    duration      = 5
    value         = 90
    time_function = "all"
  }

  warning {
    duration      = 5
    value         = 70
    time_function = "all"
  }
}

resource "newrelic_infra_alert_condition" "high_memory_usage" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  name       = "High memory usage in ${var.name}"
  type       = "infra_metric"
  event      = "K8sNodeSample"
  select     = "allocatableMemoryUtilization"
  comparison = "above"
  where      = "(clusterName = '${var.name}')"

  critical {
    duration      = 5
    value         = 90
    time_function = "all"
  }

  warning {
    duration      = 5
    value         = 70
    time_function = "all"
  }
}

resource "newrelic_infra_alert_condition" "host_not_reporting" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  name  = "Host not reporting in ${var.name}"
  type  = "infra_host_not_reporting"
  where = "(clusterName = '${var.name}')"

  critical {
    duration = 5
  }
}

resource "newrelic_infra_alert_condition" "pod_capacity_low" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  name       = "Low pod capacity in ${var.name}"
  type       = "infra_metric"
  event      = "K8sNodeSample"
  select     = "capacityPods"
  comparison = "below"
  where      = "(clusterName = '${var.name}')"

  critical {
    duration      = 5
    value         = 10
    time_function = "all"
  }

  warning {
    duration      = 5
    value         = 30
    time_function = "all"
  }
}

# Container-level alerts
resource "newrelic_infra_alert_condition" "container_memory_utilization" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  name       = "Container memory utilization high in ${var.name}"
  type       = "infra_metric"
  event      = "K8sContainerSample"
  select     = "memoryUtilization"
  comparison = "above"
  where      = "(clusterName = '${var.name}' AND containerName NOT LIKE 'hex-python-kernel')"

  critical {
    duration      = 5
    value         = 90
    time_function = "all"
  }

  warning {
    duration      = 5
    value         = 70
    time_function = "all"
  }
}

resource "newrelic_infra_alert_condition" "container_cpu_utilization" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  name       = "Container cpu utilization high in ${var.name}"
  type       = "infra_metric"
  event      = "K8sContainerSample"
  select     = "cpuCoresUtilization"
  comparison = "above"
  where      = "(clusterName = '${var.name}' AND containerName NOT LIKE 'hex-python-kernel')"

  critical {
    duration      = 5
    value         = 90
    time_function = "all"
  }

  warning {
    duration      = 5
    value         = 70
    time_function = "all"
  }
}

resource "newrelic_infra_alert_condition" "container_fs_utilization" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  name       = "Container fs utilization high in ${var.name}"
  type       = "infra_metric"
  event      = "K8sContainerSample"
  select     = "fsUsedPercent"
  comparison = "above"
  where      = "(clusterName = '${var.name}')"

  critical {
    duration      = 5
    value         = 90
    time_function = "all"
  }

  warning {
    duration      = 5
    value         = 70
    time_function = "all"
  }
}

resource "newrelic_infra_alert_condition" "deployment_container_restarts" {
  for_each  = var.monitoring_enabled ? local.deployment_names : toset([])
  policy_id = newrelic_alert_policy.default[0].id

  name       = "Containers restarting ${each.key} in cluster ${var.name}"
  type       = "infra_metric"
  event      = "K8sContainerSample"
  select     = "restartCount"
  comparison = "above"
  where      = "(clusterName = '${var.name}' and deploymentName = '${each.key}')"

  critical {
    duration      = 5
    value         = 10
    time_function = "all"
  }

  warning {
    duration      = 5
    value         = 2
    time_function = "all"
  }
}

# Alerts on deployments and statefulsets
resource "newrelic_nrql_alert_condition" "low_available_kernels" {
  for_each  = var.monitoring_enabled ? local.kernel_pools : toset([])
  policy_id = newrelic_alert_policy.default[0].id

  type                         = "static"
  name                         = "Low available kernels in ${each.key} in cluster ${var.name}"
  enabled                      = true
  violation_time_limit_seconds = 3600
  value_function               = "single_value"

  fill_option = "last_value"

  aggregation_window             = 60
  expiration_duration            = local.signal_expiration_duration
  open_violation_on_expiration   = true
  close_violations_on_expiration = true

  nrql {
    query             = "FROM K8sDeploymentSample SELECT average(podsAvailable / podsDesired * 100) WHERE (clusterName = '${var.name}' and deploymentName = '${each.key}')"
    evaluation_offset = 3
  }

  critical {
    operator              = "below"
    threshold             = 30
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "below"
    threshold             = 50
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "stateful_set_pod_missing" {
  for_each  = var.monitoring_enabled ? local.statefulset_names : toset([])
  policy_id = newrelic_alert_policy.default[0].id

  name = "Pod missing in ${each.key} in cluster ${var.name}"
  type = "static"

  enabled                      = true
  violation_time_limit_seconds = 3600
  value_function               = "single_value"

  fill_option = "none"

  aggregation_window             = 60
  expiration_duration            = local.signal_expiration_duration
  open_violation_on_expiration   = true
  close_violations_on_expiration = true

  nrql {
    query             = "FROM K8sStatefulsetSample SELECT latest(podsMissing) WHERE (clusterName = '${var.name}' and statefulsetName = '${each.key}')"
    evaluation_offset = 3
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 180
    threshold_occurrences = "ALL"
  }
}

# Bump the tolerance for the hex-deployment to avoid alerting on release
resource "newrelic_nrql_alert_condition" "hex_deployment_pods_unavailable" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  name = "Pods unavailable in ${var.name}-hex in cluster ${var.name}"
  type = "static"

  enabled                      = true
  violation_time_limit_seconds = 3600
  value_function               = "single_value"

  fill_option = "none"

  aggregation_window             = 60
  expiration_duration            = local.signal_expiration_duration
  open_violation_on_expiration   = true
  close_violations_on_expiration = true

  nrql {
    query             = "FROM K8sDeploymentSample SELECT max(podsDesired - podsAvailable) WHERE (clusterName = '${var.name}' and deploymentName = '${var.name}-hex')"
    evaluation_offset = 3
  }

  critical {
    operator              = "above"
    threshold             = 1
    threshold_duration    = 180
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "deployment_pods_unavailable" {
  for_each  = var.monitoring_enabled ? local.non_rolling_deployment_names : toset([])
  policy_id = newrelic_alert_policy.default[0].id

  name = "Pods unavailable in ${each.key} in cluster ${var.name}"
  type = "static"

  enabled                      = true
  violation_time_limit_seconds = 3600
  value_function               = "single_value"

  fill_option = "none"

  aggregation_window             = 60
  expiration_duration            = local.signal_expiration_duration
  open_violation_on_expiration   = true
  close_violations_on_expiration = true

  nrql {
    query             = "FROM K8sDeploymentSample SELECT max(podsDesired - podsAvailable) WHERE (clusterName = '${var.name}' and deploymentName = '${each.key}')"
    evaluation_offset = 3
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 180
    threshold_occurrences = "ALL"
  }
}

# Vault Alerts
resource "newrelic_nrql_alert_condition" "vault_leader_last_contact" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  type                         = "static"
  name                         = "Vault leader last contact high in ${var.name}"
  description                  = "Alert when contacting the vault leader is slow. Can indicate flapping leadership"
  enabled                      = true
  violation_time_limit_seconds = 3600
  value_function               = "single_value"

  fill_option = "last_value"

  aggregation_window             = 60
  expiration_duration            = local.signal_expiration_duration
  open_violation_on_expiration   = true
  close_violations_on_expiration = true

  nrql {
    query             = "FROM Metric SELECT average(vault_raft_leader_lastContact) WHERE instrumentation.source = '${local.prometheus_name}'"
    evaluation_offset = 3
  }

  critical {
    operator              = "above"
    threshold             = 200
    threshold_duration    = 180
    threshold_occurrences = "ALL"
  }

  warning {
    operator              = "above"
    threshold             = 100
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }
}

resource "newrelic_nrql_alert_condition" "vault_sealed" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  type                         = "static"
  name                         = "Vault sealed in ${var.name}"
  description                  = "Alert vault is sealed."
  enabled                      = true
  violation_time_limit_seconds = 3600
  value_function               = "single_value"

  fill_option = "none"

  aggregation_window             = 60
  expiration_duration            = local.signal_expiration_duration
  open_violation_on_expiration   = true
  close_violations_on_expiration = true

  nrql {
    query             = "FROM Metric SELECT latest(vault_core_unsealed) WHERE instrumentation.source = '${local.prometheus_name}'"
    evaluation_offset = 3
  }

  critical {
    operator              = "equals"
    threshold             = 0
    threshold_duration    = 180
    threshold_occurrences = "ALL"
  }
}

# NodeJS alerts
resource "newrelic_nrql_alert_condition" "high_average_node_heap_usage" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  type                         = "static"
  name                         = "Average node heap usage high in '${var.name}-hex' in cluster ${var.name}"
  description                  = "Alert when average physical memory usage is high."
  enabled                      = true
  violation_time_limit_seconds = 3600
  value_function               = "single_value"

  fill_option = "none"

  aggregation_window             = 60
  expiration_duration            = local.signal_expiration_duration
  open_violation_on_expiration   = true
  close_violations_on_expiration = true

  nrql {
    query             = "FROM Metric SELECT average(newrelic.timeslice.value) AS `MemoryUsed` WHERE metricTimesliceName = 'Memory/Physical' AND appName = '${var.name}-hex'" # Used physical memory in MB
    evaluation_offset = 3
  }

  critical {
    operator              = "above"
    threshold             = 4000
    threshold_duration    = 60
    threshold_occurrences = "AT_LEAST_ONCE"
  }

  warning {
    operator              = "above"
    threshold             = 2000
    threshold_duration    = 60
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}

resource "newrelic_nrql_alert_condition" "high_max_node_heap_usage" {
  count     = var.monitoring_enabled ? 1 : 0
  policy_id = newrelic_alert_policy.default[count.index].id

  type                         = "static"
  name                         = "Node heap usage spiked in '${var.name}-hex' in cluster ${var.name}"
  description                  = "Alert when peak physical memory usage is high."
  enabled                      = true
  violation_time_limit_seconds = 3600
  value_function               = "single_value"

  fill_option = "none"

  aggregation_window             = 60
  expiration_duration            = local.signal_expiration_duration
  open_violation_on_expiration   = true
  close_violations_on_expiration = true

  nrql {
    query             = "FROM Metric SELECT max(newrelic.timeslice.value) AS `MemoryUsed` WHERE metricTimesliceName = 'Memory/Physical' AND appName = '${var.name}-hex'" # Used physical memory in MB
    evaluation_offset = 3
  }

  critical {
    operator              = "above"
    threshold             = 7000
    threshold_duration    = 60
    threshold_occurrences = "AT_LEAST_ONCE"
  }

  warning {
    operator              = "above"
    threshold             = 5000
    threshold_duration    = 60
    threshold_occurrences = "AT_LEAST_ONCE"
  }
}
