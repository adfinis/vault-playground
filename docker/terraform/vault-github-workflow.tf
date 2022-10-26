# JWT Auth for GitHub workflow
# - https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#understanding-the-oidc-token
# - https://github.com/hashicorp/vault-action#jwt-with-github-oidc-tokens 

resource "vault_jwt_auth_backend" "github-workflow" {
  path               = "github-workflow"
  type               = "jwt"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
  default_role       = "default"
}

resource "vault_jwt_auth_backend_role" "github-workflow" {
  backend        = vault_jwt_auth_backend.github-workflow.path
  role_name      = "default"
  token_policies = ["github-workflow"]

  user_claim        = "actor"
  groups_claim      = "repository_owner"
  role_type         = "jwt"
  token_ttl         = 3600 #1h
  token_num_uses    = 0
  bound_claims_type = "glob"
  bound_claims = {
    repository       = "adfinis-sygroup/vault-playground"
    job_workflow_ref = "adfinis-sygroup/vault-playground/.github/workflows/vault.yml*"
  }
  bound_audiences = ["https://github.com/adfinis-sygroup"]
}
