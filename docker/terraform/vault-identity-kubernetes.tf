resource "vault_identity_entity" "kubernetes_kv" {
  name = "kubernetes-kv"
}

# The name of the alias needs to match the ID of the ServiceAccount in kubernetes:
# https://www.vaultproject.io/docs/concepts/identity#mount-bound-aliases
resource "vault_identity_entity_alias" "kubernetes_kv" {
  name           = "7a04b18b-633c-431c-91e3-b4e57d0f4db1"
  mount_accessor = vault_auth_backend.kubernetes.accessor
  canonical_id   = vault_identity_entity.kubernetes_kv.id
}

# Create internal group inside the namespace with
# Policy to access the namespace and the KV engine (read-only)
resource "vault_identity_group" "kubernetes_kv" {
  depends_on       = [module.groups]
  namespace        = "tenant"
  name             = "kubernetes-kv"
  type             = "internal"
  policies         = ["default", "kv-r"]
  member_group_ids = [vault_identity_group.kubernetes_kv_root.id]
}

# Create group in root namespace with ServiceAccount entity
resource "vault_identity_group" "kubernetes_kv_root" {
  name              = "kubernetes-kv"
  type              = "internal"
  policies          = ["default"]
  member_entity_ids = [vault_identity_entity.kubernetes_kv.id]
}
