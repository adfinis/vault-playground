provider "keycloak" {
  client_id = "admin-cli"
  username  = "admin"
  password  = "admin"
  url       = "http://keycloak.${var.container_domain}:8080"
}

locals {
  container_domain_dc1 = split(".", var.container_domain)[0]
  container_domain_dc2 = split(".", var.container_domain)[1]
}

resource "keycloak_realm" "realm" {
  realm   = join("-", split(".", var.container_domain))
  enabled = true
}

# Add the FreeIPA 389 Directory Server as User Federation Provider
# https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/ldap_user_federation
resource "keycloak_ldap_user_federation" "ldap_user_federation" {
  name     = "FreeIPA"
  realm_id = keycloak_realm.realm.id
  enabled  = true

  username_ldap_attribute = "uid"
  rdn_ldap_attribute      = "uid"
  uuid_ldap_attribute     = "nsuniqueid"
  user_object_classes = [
    "inetOrgPerson",
    "organizationalPerson"
  ]
  connection_url  = "ldap://ipa.${var.container_domain}"
  users_dn        = "cn=users,cn=accounts,dc=${local.container_domain_dc1},dc=${local.container_domain_dc2}"
  bind_dn         = "uid=admin,cn=users,cn=accounts,dc=${local.container_domain_dc1},dc=${local.container_domain_dc2}"
  bind_credential = "Secret123"
}

resource "keycloak_ldap_group_mapper" "ldap_group_mapper" {
  realm_id                = keycloak_realm.realm.id
  ldap_user_federation_id = keycloak_ldap_user_federation.ldap_user_federation.id
  name                    = "groups"

  ldap_groups_dn            = "cn=groups,cn=accounts,dc=${local.container_domain_dc1},dc=${local.container_domain_dc2}"
  group_name_ldap_attribute = "cn"
  group_object_classes = [
    "groupOfNames"
  ]
  membership_attribute_type      = "DN"
  membership_ldap_attribute      = "member"
  membership_user_ldap_attribute = "uid"
  memberof_ldap_attribute        = "memberOf"
}

# Add Vault as OpenID Connect Client
# - https://www.vaultproject.io/docs/auth/jwt/oidc_providers
# - https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "openid_client" {
  realm_id  = keycloak_realm.realm.id
  client_id = "hashicorp-vault"

  name    = "HashiCorp Vault vault.${var.container_domain}"
  enabled = true

  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  valid_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "http://vault.${var.container_domain}:8200/ui/vault/auth/oidc/oidc/callback"
  ]
}

# Add Vault as OpenID Connect Client for JWT
resource "keycloak_openid_client" "jwt_client" {
  realm_id  = keycloak_realm.realm.id
  client_id = "hashicorp-vault-jwt"

  name    = "HashiCorp Vault vault.${var.container_domain}"
  enabled = true

  access_type           = "PUBLIC"
  standard_flow_enabled = true
  direct_access_grants_enabled = true

  valid_redirect_uris = [
    "http://localhost:8250/jwt/callback",
    "http://vault.${var.container_domain}:8200/ui/vault/auth/jwt/oidc/callback"
  ]
}

resource "keycloak_generic_client_protocol_mapper" "openid_client_groups" {
  realm_id        = keycloak_realm.realm.id
  client_id       = keycloak_openid_client.openid_client.id
  name            = "groups-vault-oidc"
  protocol        = "openid-connect"
  protocol_mapper = "oidc-group-membership-mapper"
  config = {
    "access.token.claim"   = "true"
    "id.token.claim"       = "true"
    "claim.name"           = "groups"
    "full.path"            = "false"
    "userinfo.token.claim" = "true"
  }
}

resource "keycloak_generic_client_protocol_mapper" "jwt_client_groups" {
  realm_id        = keycloak_realm.realm.id
  client_id       = keycloak_openid_client.jwt_client.id
  name            = "groups-vault-jwt"
  protocol        = "openid-connect"
  protocol_mapper = "oidc-group-membership-mapper"
  config = {
    "access.token.claim"   = "true"
    "id.token.claim"       = "true"
    "claim.name"           = "groups"
    "full.path"            = "false"
    "userinfo.token.claim" = "true"
  }
}

