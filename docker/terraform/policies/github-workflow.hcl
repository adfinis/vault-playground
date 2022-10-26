# Allow creating limited child token. Required for TF provider Vault:
# https://registry.terraform.io/providers/hashicorp/vault/latest/docs#token
path "auth/token/create" {
    capabilities = ["create", "update"]
}

path "tenant/kv/+/foo-secret " {
    capabilities = ["read"]
}
