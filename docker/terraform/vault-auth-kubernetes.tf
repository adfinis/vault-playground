data "external" "cacerts" {
  program = ["sh", "${path.root}/scripts/get-cacerts.sh", "${var.container_domain}"]
}
data "external" "auth_delegator_sa_token" {
  program = ["sh", "${path.root}/scripts/get-k8s-auth-delegator-sa-token.sh", "${var.container_domain}"]
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://k3s-server.${var.container_domain}:6443"
  kubernetes_ca_cert = data.external.cacerts.result.cacerts
  issuer             = "https://kubernetes.default.svc.cluster.local"
  # token_reviewer_jwt = data.external.auth_delegator_sa_token.result.token
  token_reviewer_jwt = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjdrQkF0LXZkOVVDZnN3eXJFMVJFVVo5LUFhZTVRQVNoaUdIa01YUzVRUDAifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiLCJrM3MiXSwiZXhwIjoxNjg4MDI1NzY4LCJpYXQiOjE2NTY0ODk3NjgsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJ2YXVsdC1jc2ktcHJvdmlkZXIiLCJwb2QiOnsibmFtZSI6InZhdWx0LWNzaS1wcm92aWRlci1zbG1ydCIsInVpZCI6IjgwYzE1MWRlLWEzMDctNGY0MS05YjAzLTAyN2FhM2QwYmRjMCJ9LCJzZXJ2aWNlYWNjb3VudCI6eyJuYW1lIjoidmF1bHQtY3NpLXByb3ZpZGVyIiwidWlkIjoiZjIzZDJkZWEtM2Q0Mi00YWQ4LWI4YzktNzY5Y2NlOTMzZDI1In0sIndhcm5hZnRlciI6MTY1NjQ5MzM3NX0sIm5iZiI6MTY1NjQ4OTc2OCwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OnZhdWx0LWNzaS1wcm92aWRlcjp2YXVsdC1jc2ktcHJvdmlkZXIifQ.IHB5n98CwvEdAVPHlOgIvtlM_ZBhkfLh8KTYlC5G1Wec2EW1mc8z6wvV7JT42gZlRK6BllSB8Fw8DElK12TNjg08IlbxrApFR8p5g4jgjHEONr_mBnCXUhFBBA8vToRXppj6PCXd1w6ndWcKUXgb_9WXUFoGJsKNCpuLW0uy5rvk0z9bgr3KLi-qw31x3RFlXM2ZAHX4wkTx6lroS9FTOkTzdJD5WUrX8zt4YvmUt0CiSqjYVr3eAIl_fhrrBMp81JBUDYEekuCuShT4oys0lOf2647kvVTY9ihSaQIu-vzmXuzjKSrYWK37_vTpy8swIFCcpzXu0h19nHjXtwby7Q"
}

resource "vault_kubernetes_auth_backend_role" "csi-provider" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "kv-r"
  bound_service_account_names      = ["vault-kv"]
  bound_service_account_namespaces = ["*"]
  token_ttl                        = 1200
}
