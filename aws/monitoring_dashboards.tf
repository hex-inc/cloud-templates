resource "newrelic_one_dashboard" "overview" {
  count = var.monitoring_enabled ? 1 : 0
  name  = "Overview of ${local.monitoring_cluster_name}"
  page {
    name = "Overview of ${local.monitoring_cluster_name}"

    widget_line {
      title = "Cluster CPU"
      nrql_query {
        query = "SELECT average(allocatableCpuCoresUtilization) AS 'CPU Utilization' FROM K8sNodeSample WHERE clusterName = '${var.name}' TIMESERIES AUTO"
      }
      row    = 1
      column = 1
    }

    widget_line {
      title = "Cluster Disk"
      nrql_query {
        query = "SELECT average(fsCapacityUtilization) AS 'FS Utilization' FROM K8sNodeSample WHERE clusterName = '${var.name}' TIMESERIES AUTO"
      }
      row    = 1
      column = 2
    }

    widget_line {
      title = "Cluster Memory"
      nrql_query {
        query = "SELECT average(allocatableMemoryUtilization) AS 'Memory Utilization' FROM K8sNodeSample WHERE clusterName = '${var.name}' TIMESERIES AUTO"
      }
      row    = 1
      column = 3
    }

    widget_line {
      title = "Container CPU"
      nrql_query {
        query = "SELECT average(cpuCoresUtilization) AS 'CPU Utilization' FROM K8sContainerSample WHERE clusterName = '${var.name}' FACET deploymentName TIMESERIES AUTO"
      }
      row    = 2
      column = 1
    }

    widget_line {
      title = "Container FS"
      nrql_query {
        query = "SELECT average(fsUsedPercent) AS 'FS Utilization %' FROM K8sContainerSample WHERE clusterName = '${var.name}' FACET deploymentName TIMESERIES AUTO"
      }
      row    = 2
      column = 2
    }

    widget_line {
      title = "Container Memory"
      nrql_query {
        query = "SELECT average(memoryUtilization) AS 'Memory Utilization' FROM K8sContainerSample WHERE clusterName = '${var.name}' FACET deploymentName TIMESERIES AUTO"
      }
      row    = 2
      column = 3
    }
  }
}
