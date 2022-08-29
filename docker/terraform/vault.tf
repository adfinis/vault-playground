locals {
  # Read all groups and namespace assignments from the input YAML
  groups = yamldecode(file("${path.root}/groups.yaml")).groups
  groups_to_namespaces = flatten([
    for group_key, group_value in local.groups : [
      for namespace_key, namespace_value in group_value.namespaces : {
        namespace_key = namespace_key
        group_key     = group_key
        metadata      = group_value.metadata
      }
    ]
  ])
}

# Provider for the Root namespace
provider "vault" {}

# Create the namespaces
resource "vault_namespace" "namespace" {
  for_each = toset(distinct(local.groups_to_namespaces[*].namespace_key))
  path     = each.value
}

# Authorization on namespaces
module "groups" {
  for_each   = local.groups
  source     = "./groups"
  namespaces = each.value.namespaces
  group      = each.key
  metadata   = each.value.metadata
  depends_on = [vault_jwt_auth_backend.oidc, vault_jwt_auth_backend.jwt, vault_namespace.namespace]
}

# KV engine inside the namespace
resource "vault_mount" "kv" {
  for_each   = toset(distinct(local.groups_to_namespaces[*].namespace_key))
  namespace  = each.key
  path       = "kv"
  type       = "kv-v2"
  depends_on = [vault_namespace.namespace]
}

resource "time_sleep" "wait_3_seconds" {
  depends_on      = [vault_mount.kv]
  create_duration = "3s"
}

resource "null_resource" "kv1_to_kv2_migration" {
  depends_on = [time_sleep.wait_3_seconds]
}

# Write a test secret
resource "vault_generic_secret" "example" {
  path       = "tenant/kv/foo-secret"
  data_json  = <<EOT
{
  "password": "123"
}
EOT
  depends_on = [null_resource.kv1_to_kv2_migration]
}

