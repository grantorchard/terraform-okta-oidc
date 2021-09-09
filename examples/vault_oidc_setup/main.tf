provider "okta" {
  #api_token = "00G6YpUE8G4cAEUbzN4zxH8lxnkIhMJCK7lZTrb9e8"
  org_name  = "hashicorp-go"
  base_url  = "okta.com"
  api_token = "00G6YpUE8G4cAEUbzN4zxH8lxnkIhMJCK7lZTrb9e8"
}

## Import OIDC module
module "okta_oidc" {
  source = "../../../terraform-okta-oidc"

  auth_server_audiences = [
    "api://vault"
  ]
  redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "https://localhost:8200/ui/vault/auth/oidc/oidc/callback"
  ]
  app_groups = [
    okta_group.vault_admins.id
  ]
}

resource "okta_group" "vault_admins" {
  name = "vault admins"
}

resource "okta_user" "grant" {
  first_name = "Grant"
  last_name  = "Orchard"
  email      = "gary.groundwork@gmail.com"
  login      = "gary.groundwork@gmail.com"
  password   = "Hashi123!"
}

data "okta_user" "go" {
  user_id = "go@hashicorp.com"
}

resource "okta_group_memberships" "vault_admins" {
  group_id = okta_group.vault_admins.id
  users = [
    okta_user.grant.id,
    data.okta_user.go.id
  ]
}

## Create JWT auth backed, and a default role
resource "vault_jwt_auth_backend" "this" {
  type               = "oidc"
  path               = "okta"
  oidc_discovery_url = module.okta_oidc.issuer
  oidc_client_id     = module.okta_oidc.client_id
  oidc_client_secret = module.okta_oidc.client_secret
  default_role       = "default"
}

resource "vault_jwt_auth_backend_role" "this" {
  backend   = vault_jwt_auth_backend.this.path
  role_name = "default"
  token_policies = [
    "default"
  ]
  user_claim           = "preferred_username"
  role_type            = "oidc"
  groups_claim         = "groups"
  oidc_scopes          = ["openid", "profile"]
  verbose_oidc_logging = true

  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "https://localhost:8200/ui/vault/auth/oidc/oidc/callback"
  ]
}

resource "vault_identity_group" "vault_admins" {
  name = "vault_admins"
  type = "external"
  policies = [
    vault_policy.vault_admins.name
  ]
}

resource "vault_identity_group_alias" "vault_admins" {
  name           = okta_group.vault_admins.name
  mount_accessor = vault_jwt_auth_backend.this.accessor
  canonical_id   = vault_identity_group.vault_admins.id
}

# Please never use a policy like this, it is only provided as a proof of functionality.
resource "vault_policy" "vault_admins" {
  name   = "vault_admins"
  policy = <<EOT
path "*" {
  capabilities = ["create", "read", "list", "update", "delete", "sudo"]
}
EOT
}