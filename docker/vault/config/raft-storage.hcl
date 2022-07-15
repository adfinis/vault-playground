ui = true

listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
  telemetry {
    unauthenticated_metrics_access = true
  }
}

storage "raft" {
  path = "/vault/file"
}