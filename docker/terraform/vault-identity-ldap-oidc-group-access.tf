# External group for ldap authorization
resource "vault_identity_group" "ldap_testgroup_external" {
  name = "ldap-testgroup-external"
  type = "external"
}
# External group alias that maps to the auth backend
resource "vault_identity_group_alias" "ldap_tenant_alias" {
  name           = "testgroup"
  mount_accessor = vault_ldap_auth_backend.ldap.accessor
  canonical_id   = vault_identity_group.ldap_testgroup_external.id
}

# These group resources are already created in the "namespace" module
# resource "vault_identity_group" "oidc_testgroup_external" {
#   name = "oidc-testgroup-external"
#   type = "external"
# }
# resource "vault_identity_group_alias" "oidc_tenant_alias" {
#   name           = "testgroup"
#   mount_accessor = vault_jwt_auth_backend.oidc.accessor
#   canonical_id   = vault_identity_group.oidc_testgroup_external.id
# }

# The external groups that reference the authentication backends in the
# root namespace (accessor mapping) are member of this internal group.
resource "vault_identity_group" "internal_tenant" {
  depends_on = [module.groups]
  namespace  = "tenant"
  name       = "testgroup-internal"
  member_group_ids = [
    vault_identity_group.ldap_testgroup_external.id,
    # This mapping for oidc auth was already done in the "namespace" module
    # vault_identity_group.oidc_testgroup_external.id
  ]
  # Map the default policy of the namespace,
  # or any other policy from within the namespace
  policies = ["default"]
}
