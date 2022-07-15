provider "keycloak" {
  client_id = "admin-cli"
  username  = "admin"
  password  = "admin"
  url       = "http://keycloak.identity.net:8080"
}

resource "keycloak_realm" "realm" {
  realm   = "Identity-Net"
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
  connection_url  = "ldap://ipa.identity.net"
  users_dn        = "cn=users,cn=accounts,dc=identity,dc=net"
  bind_dn         = "uid=admin,cn=users,cn=accounts,dc=identity,dc=net"
  bind_credential = "Secret123"
}

resource "keycloak_ldap_group_mapper" "ldap_group_mapper" {
  realm_id                = keycloak_realm.realm.id
  ldap_user_federation_id = keycloak_ldap_user_federation.ldap_user_federation.id
  name                    = "groups"

  ldap_groups_dn            = "cn=groups,cn=accounts,dc=identity,dc=net"
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

  name    = "HashiCorp Vault vault.identity.net"
  enabled = true

  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  valid_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "http://vault.identity.net:8200/ui/vault/auth/oidc/oidc/callback"
  ]
}
resource "keycloak_generic_client_protocol_mapper" "groups" {
  realm_id        = keycloak_realm.realm.id
  client_id       = keycloak_openid_client.openid_client.id
  name            = "groups"
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