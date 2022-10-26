data "vault_approle_auth_backend_role_id" "role" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.kv.role_name
}

# Create Entity and Alias for the AppRole
resource "vault_identity_entity" "approle_kv" {
  name = "approle-kv"
}
# The name of the Alias needs to match the Role ID of the AppRole
# https://www.vaultproject.io/docs/concepts/identity#mount-bound-aliases
resource "vault_identity_entity_alias" "approle_kv" {
  name           = data.vault_approle_auth_backend_role_id.role.role_id
  mount_accessor = vault_auth_backend.approle.accessor
  canonical_id   = vault_identity_entity.approle_kv.id
}

# Create internal groups inside the namespace
resource "vault_identity_group" "approle_kv_r_tenant" {
  depends_on = [module.groups]
  namespace  = "tenant"
  name       = "approle-kv"
  type       = "internal"
  # The default policy of the namespace allows the AppRole client
  # to access the namespace. The kv policy allows the client to
  # read the secrets in the kv engine, see folder "policies"
  policies         = ["default", "kv-r"]
  member_group_ids = [vault_identity_group.approle_kv_r_root.id]
}
# Internal group in the Root namespace with the AppRole Entity member
resource "vault_identity_group" "approle_kv_r_root" {
  name              = "approle-kv"
  type              = "internal"
  policies          = ["default"]
  member_entity_ids = [vault_identity_entity.approle_kv.id]
}
