# Create Entity and Alias for the kv-wrtier LDAP user
resource "vault_identity_entity" "kv_writer" {
  name = "kv-writer"
}
# The name of the Alias needs to match the LDAP username
# https://www.vaultproject.io/docs/concepts/identity#mount-bound-aliases
resource "vault_identity_entity_alias" "kv_writer" {
  name           = "kv-writer"
  mount_accessor = vault_ldap_auth_backend.ldap.accessor
  canonical_id   = vault_identity_entity.kv_writer.id
}

# Internal group in Root namespace with the users
# granted rw access on the KV engine inside the namespace
resource "vault_identity_group" "kv_rw_root" {
  name                       = "kv-rw"
  type                       = "internal"
  policies                   = ["default"]
  external_member_entity_ids = true
}
resource "vault_identity_group_member_entity_ids" "kv_rw" {
  member_entity_ids = [
    vault_identity_entity.kv_writer.id
  ]
  exclusive = false
  group_id  = vault_identity_group.kv_rw_root.id
}

# Internal group inside the namespace for rw access.
# The group of the Root namespace is member of this group.
resource "vault_identity_group" "kv_rw_tenant" {
  depends_on       = [module.groups]
  namespace        = "tenant"
  name             = "kv-rw"
  type             = "internal"
  policies         = ["default", "kv-rw"]
  member_group_ids = [vault_identity_group.kv_rw_root.id]
}
