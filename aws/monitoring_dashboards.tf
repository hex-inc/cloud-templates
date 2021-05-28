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

  widget {
    title         = "Average Backend Response Time"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(`provider.targetResponseTime.Average`) FROM LoadBalancerSample WHERE `label.kubernetes.io/cluster/${var.name}` = 'owned' and provider  = 'AlbTargetGroup' TIMESERIES facet displayName UNTIL 10 minutes ago"
    row           = 3
    column        = 1
  }

  widget {
    title         = "Load Balancer HTTP Request Errors"
    visualization = "faceted_line_chart"
    nrql          = "SELECT sum(`provider.httpCodeTarget3XXCount.Sum`) as '300 errors (backend)', sum(`provider.httpCodeTarget4XXCount.Sum`) as '400 errors (backend)', sum(`provider.httpCodeTarget5XXCount.Sum`) as '500 errors (backend)', sum(`provider.httpCodeElb4XXCount.Sum`) as '400 errors (frontend)', sum(`provider.httpCodeElb5XXCount.Sum`) as '500 errors (frontend)' FROM LoadBalancerSample WHERE `label.kubernetes.io/cluster/${var.name}` = 'owned' AND provider in ('Alb', 'AlbTargetGroup') TIMESERIES UNTIL 10 minutes ago"
    row           = 3
    column        = 2
  }

  widget {
    title         = "Load Balancer Unhealthy Host Count"
    visualization = "faceted_line_chart"
    nrql          = "SELECT max(provider.unHealthyHostCount.Maximum) FROM LoadBalancerSample WHERE `label.kubernetes.io/cluster/${var.name}` = 'owned' and provider  = 'AlbTargetGroup' TIMESERIES facet displayName UNTIL 10 minutes ago"
    row           = 3
    column        = 3
  }

  widget {
    title         = "RDS CPU"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(`provider.cpuUtilization.total`) from DatastoreSample where provider = 'RdsDbInstance' and displayName = '${var.name}' TIMESERIES AUTO"
    row           = 4
    column        = 1
  }

  widget {
    title         = "RDS Read Operations per Second"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(`provider.readIops.Average`) as 'Read Operations' From DatastoreSample WHERE provider = 'RdsDbInstance' AND displayName = '${var.name}' SINCE 6 hour ago TIMESERIES UNTIL 10 minutes ago"
    row           = 4
    column        = 2
  }

  widget {
    title         = "RDS Write Operations per Second"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(`provider.writeIops.Average`) as 'Write Operations' From DatastoreSample WHERE provider = 'RdsDbInstance' AND displayName = '${var.name}' SINCE 6 hour ago TIMESERIES AUTO UNTIL 10 minutes ago"
    row           = 4
    column        = 3
  }
  widget {
    title         = "RDS Database Connections"
    visualization = "billboard"
    nrql          = "SELECT average(`provider.databaseConnections.Average`) as 'connections in use' From DatastoreSample WHERE provider = 'RdsDbInstance' AND displayName = '${var.name}' since 1 hour ago until 10 minutes ago"
    row           = 5
    column        = 1
  }

  widget {
    title         = "RDS Read Latency (s)"
    visualization = "faceted_line_chart"
    nrql          = "SELECT sum(`provider.readLatency.Sum`) / 60 as 'seconds' From DatastoreSample WHERE provider = 'RdsDbInstance' AND displayName = '${var.name}' SINCE 3 hours ago TIMESERIES AUTO UNTIL 10 minutes ago"
    row           = 5
    column        = 2
  }

  widget {
    title         = "RDS Write Latency (s)"
    visualization = "faceted_line_chart"
    nrql          = "SELECT sum(`provider.writeLatency.Sum`) / 60 as 'seconds' From DatastoreSample WHERE provider = 'RdsDbInstance' AND displayName = '${var.name}' SINCE 3 hours ago TIMESERIES AUTO UNTIL 10 minutes ago"
    row           = 5
    column        = 3
  }

  widget {
    title         = "RDS FS Used %"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(`provider.fileSys.used`)/average(`provider.fileSys.total`) as 'FS Utilization %' from DatastoreSample WHERE provider = 'RdsDbInstance' AND displayName = '${var.name}' TIMESERIES AUTO"
    row           = 6
    column        = 1
  }

  widget {
    title         = "RDS Freeable Memory"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(`provider.freeableMemory.Average`) as 'Freeable Memory' from DatastoreSample WHERE provider = 'RdsDbInstance' AND displayName = '${var.name}' TIMESERIES AUTO UNTIL 10 minutes ago"
    row           = 6
    column        = 2
  }

  widget {
    title         = "RDS Disk Read/Write (Kbps)"
    visualization = "faceted_line_chart"
    nrql          = "SELECT average(`provider.diskIo.writeKbps`) as 'Write Kb/sec', average(`provider.diskIo.readKbps`) as 'Read Kb/sec' from DatastoreSample WHERE provider = 'RdsDbInstance' AND displayName = '${var.name}' TIMESERIES AUTO"
    row           = 6
    column        = 3
  }
}
