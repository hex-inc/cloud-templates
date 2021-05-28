resource "newrelic_dashboard" "overview" {
  count = var.monitoring_enabled ? 1 : 0
  title = "Overview of ${local.monitoring_cluster_name}"

  widget {
    title         = "Cluster CPU"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(allocatableCpuCoresUtilization) AS 'CPU Utilization' FROM K8sNodeSample WHERE clusterName = '${var.name}' TIMESERIES AUTO"
    row           = 1
    column        = 1
  }

  widget {
    title         = "Cluster Disk"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(fsCapacityUtilization) AS 'FS Utilization' FROM K8sNodeSample WHERE clusterName = '${var.name}' TIMESERIES AUTO"
    row           = 1
    column        = 2
  }

  widget {
    title         = "Cluster Memory"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(allocatableMemoryUtilization) AS 'Memory Utilization' FROM K8sNodeSample WHERE clusterName = '${var.name}' TIMESERIES AUTO"
    row           = 1
    column        = 3
  }

  widget {
    title         = "Container CPU"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(cpuCoresUtilization) AS 'CPU Utilization' FROM K8sContainerSample WHERE clusterName = '${var.name}' FACET deploymentName TIMESERIES AUTO"
    row           = 2
    column        = 1
  }

  widget {
    title         = "Container FS"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(fsUsedPercent) AS 'FS Utilization %' FROM K8sContainerSample WHERE clusterName = '${var.name}' FACET deploymentName TIMESERIES AUTO"
    row           = 2
    column        = 2
  }

  widget {
    title         = "Container Memory"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(memoryUtilization) AS 'Memory Utilization' FROM K8sContainerSample WHERE clusterName = '${var.name}' FACET deploymentName TIMESERIES AUTO"
    row           = 2
    column        = 3
  }
}
