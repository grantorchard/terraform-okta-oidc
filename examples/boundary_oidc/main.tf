provider "boundary" {
  addr             = "http://127.0.0.1:9200"
  recovery_kms_hcl = <<EOT
kms "aead" {
  purpose = "recovery"
  aead_type = "aes-gcm"
  key = "tR9TkO2Cfxt7cvwhwsPdCCe5h8KI/zWwA2dIMz0lfd8="
  key_id = "global_recovery"
}
EOT
}

## Import OIDC module
module "okta_oidc" {
  source = "github.com/grantorchard/terraform-okta-oidc"

  auth_server_audiences = [
    "api://boundary"
  ]

  redirect_uris = [
    "http://localhost:9200/v1/auth-methods/oidc:authenticate:callback"
  ]

  app_group_assignments = [
    okta_group.boundary_admins.id
  ]

	groups_claim = [
		{
			type  = "FILTER"
			name        = "groups"
			filter_type = "CONTAINS"
			value       = "boundary"
  	}
	]
}

resource "okta_group" "boundary_admins" {
  name = "boundary admins"
}

data "okta_user" "go" {
  user_id = "go@hashicorp.com"
}

resource "okta_group_memberships" "boundary_admins" {
  group_id = okta_group.boundary_admins.id
  users = [
    data.okta_user.go.id
  ]
}

resource "boundary_role" "boundary_admin" {
  scope_id       = "global"
  grant_scope_id = "global"
  grant_strings = [
    "id=*;type=*;actions=*"
  ]

  principal_ids = [
		boundary_managed_group.this.id
	]
	name = "boundary_admins"
}

resource "boundary_auth_method_oidc" "this" {
  name                = "okta"
  scope_id            = "global"
	state               = "active-public"
	is_primary_for_scope = true
	callback_url        = "http://localhost:9200/v1/auth-methods/oidc:authenticate:callback"
  issuer              = module.okta_oidc.issuer
  client_id           = module.okta_oidc.client_id
  client_secret       = module.okta_oidc.client_secret
	allowed_audiences   = [
		module.okta_oidc.client_id
	]
  signing_algorithms  = [ "RS256" ]
  api_url_prefix      = "http://localhost:9200"
	account_claim_maps  = []
	claims_scopes       = [
		"email",
		"profile"
	]
}

resource "boundary_managed_group" "this" {
	auth_method_id = boundary_auth_method_oidc.this.id
	filter = "\"/token/groups\" contains \"${okta_group.boundary_admins.name}\""
	name = "boundary_admins"
}

resource "boundary_account_oidc" "this" {
	name = data.okta_user.go.email
	scope_id = "global"
}