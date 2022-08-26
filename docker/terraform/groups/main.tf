data "vault_auth_backend" "oidc" {
  #path = "ldap"
  path = "oidc"
}

# For each Admin group, create External groups/aliases
resource "vault_identity_group" "external_group" {
  name     = "${data.vault_auth_backend.oidc.path}-${var.group}-external"
  type     = "external"
  policies = [for k, v in var.namespaces : "${k}_admin"]
  metadata = var.metadata
}
resource "vault_identity_group_alias" "group_alias" {
  name           = var.group
  mount_accessor = data.vault_auth_backend.oidc.accessor
  canonical_id   = vault_identity_group.external_group.id
}

# For each Admin group, create internal group inside the customer namespace
resource "vault_identity_group" "internal_group" {
  for_each = var.namespaces
  name     = "${each.key}_${vault_identity_group.external_group.name}_admin"
  member_group_ids = [
    vault_identity_group.external_group.id
  ]
  # Map the default policy of the namespace,
  # or any other policy from within the namespace
  policies  = ["default"]
  namespace = each.key
  metadata  = var.metadata
}

# Admin policy in the Root namespace
resource "vault_policy" "admin_policy" {
  for_each = var.namespaces
  name     = "${each.key}_admin"
  policy   = <<EOT
# Full permissions on the namespace
path "${each.key}/*" {
  capabilities = ["create", "read", "update", "delete", "list", "patch", "sudo"]
}

path "${each.key}/identity/group/id/${vault_identity_group.internal_group[each.key].id}" {
  # No permissions on the internal group (for the paranoid admin)
  #capabilities = ["deny"]
  # Read permissions on the group to allow reading group metadata
  capabilities = ["read"]
}
EOT
}
