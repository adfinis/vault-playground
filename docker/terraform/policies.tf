locals {
  root_policies = fileset(path.root, "policies/*.hcl")
  tenant_policies = flatten([
    for n in vault_namespace.namespace : [
      for f in fileset(path.root, "policies/tenant/*.hcl") : {
        policy-name     = split(".", basename(f))[0]
        policy-contents = file(f)
        namespace-path  = n.path
      }
    ]
  ])
}

# Vault policies in Root namespace
resource "vault_policy" "policy" {
  for_each = local.root_policies
  name     = split(".", basename(each.value))[0]
  policy   = file(each.value)
}

# Policies in the other namespaces
resource "vault_policy" "tenant-policy" {
  for_each = {
    for p in local.tenant_policies : "${p.namespace-path}-${p.policy-name}" => p
  }
  name      = each.value.policy-name
  policy    = each.value.policy-contents
  namespace = each.value.namespace-path
}
