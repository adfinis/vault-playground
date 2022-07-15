telemetry {
  usage_gauge_period = "1m"
  prometheus_retention_time = "24h"
  # Don't prefix gauge values with the local hostname
  disable_hostname = true
}
