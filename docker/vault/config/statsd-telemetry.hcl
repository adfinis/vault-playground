telemetry {
  # replace with host.containers.internal for pdoamn
  statsd_address = host.docker.internal:8125
  disable_hostname = true
}

