# LDAP auth backend
# - https://www.vaultproject.io/docs/auth/ldap
# - https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/ldap_auth_backend
resource "vault_ldap_auth_backend" "ldap" {
  path         = "ldap"
  url          = "ldaps://ipa.identity.net"
  insecure_tls = true
  userdn       = "cn=users,cn=accounts,dc=identity,dc=net"
  userattr     = "uid"
  groupdn      = "cn=groups,cn=accounts,dc=identity,dc=net"
  groupfilter  = "(|(memberUid={{.Username}})(member={{.UserDN}})(uniqueMember={{.UserDN}}))"
  groupattr    = "cn"
}

# OIDC auth backend
# - https://www.vaultproject.io/docs/auth/jwt/oidc_providers#keycloak
# - https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend
resource "vault_jwt_auth_backend" "oidc" {
  path         = "oidc"
  type         = "oidc"
  default_role = "default"
  # https://www.keycloak.org/docs/latest/securing_apps
  oidc_discovery_url = "http://keycloak.identity.net:8080/auth/realms/${keycloak_realm.realm.realm}"
  oidc_client_id     = keycloak_openid_client.openid_client.client_id
  oidc_client_secret = keycloak_openid_client.openid_client.client_secret
}
resource "vault_jwt_auth_backend_role" "keycloak" {
  backend        = vault_jwt_auth_backend.oidc.path
  role_name      = "default"
  token_policies = ["default"]

  user_claim   = "email"
  groups_claim = "groups"
  role_type    = "oidc"
  # https://www.vaultproject.io/docs/auth/jwt#redirect-uris
  allowed_redirect_uris = [
    "http://vault.identity.net:8200/ui/vault/auth/oidc/oidc/callback",
    "http://localhost:8250/oidc/callback"
  ]
  # verbose_oidc_logging = true
}