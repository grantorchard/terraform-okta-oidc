provider "okta" {
  #api_token = "00G6YpUE8G4cAEUbzN4zxH8lxnkIhMJCK7lZTrb9e8"
  org_name  = "hashicorp-go"
  base_url  = "okta.com"
  api_token = "00G6YpUE8G4cAEUbzN4zxH8lxnkIhMJCK7lZTrb9e8"
}

provider "consul" {
	token = "bb611989-2468-a30f-ad32-d97f47f4d119"
}

locals {
	oidc_discovery_url = module.okta_oidc.issuer
  oidc_client_id     = module.okta_oidc.client_id
  oidc_client_secret = module.okta_oidc.client_secret
	redirect_uris = [
		"http://localhost:8550/oidc/callback",
		"http://localhost:8550/okta/callback",
		"http://localhost:8550/okta/oidc/callback",
		"http://localhost:8550/oidc/okta/callback",
    "http://localhost:8500/ui/oidc/callback",
		"http://localhost:8500/ui/okta/callback",
		"http://localhost:8500/ui/oidc/oidc/callback",
		"http://localhost:8500/ui/oidc/okta/callback",
		"http://localhost:8500/ui/okta/oidc/callback"
		#"http://localhost:8200/ui/vault/auth/oidc/oidc/callback"
	]
}

module "okta_oidc" {
  source = "../../../terraform-okta-oidc"

  auth_server_audiences = [
    "api://consul"
  ]
  redirect_uris = local.redirect_uris

  app_group_assignments = [
    okta_group.consul_admins.id
  ]
	groups_claim = [
		{
			type        = "FILTER"
			name        = "groups"
			filter_type = "CONTAINS"
			value       = "consul"
  	}
	]
}

resource "okta_group" "consul_admins" {
  name = "consul_admins"
}

data "okta_user" "go" {
  user_id = "go@hashicorp.com"
}

resource "okta_group_memberships" "consul_admins" {
  group_id = okta_group.consul_admins.id
  users = [
    data.okta_user.go.id
  ]
}


resource "consul_acl_auth_method" "oidc" {
  name        = "oidc"
  type        = "oidc"
	max_token_ttl = "600s"

  config_json = jsonencode({
		"AllowedRedirectURIs": "${local.redirect_uris}",
		"BoundAudiences": "${local.oidc_client_id}",
		"OIDCClientID": "${local.oidc_client_id}",
		"OIDCClientSecret": "${local.oidc_client_secret}",
		"OIDCDiscoveryURL": "${local.oidc_discovery_url}",
		"OIDCScopes": [
			"openid",
			"profile",
			"email"
		],
		"ListClaimMappings": {
			"groups": "groups"
		},
		"VerboseOIDCLogging": true
	})
}

resource "consul_acl_auth_method" "okta" {
  name        = "okta"
  type        = "oidc"
	max_token_ttl = "600s"

  config_json = jsonencode({
		"AllowedRedirectURIs": "${local.redirect_uris}",
		"BoundAudiences": "${local.oidc_client_id}",
		"OIDCClientID": "${local.oidc_client_id}",
		"OIDCClientSecret": "${local.oidc_client_secret}",
		"OIDCDiscoveryURL": "${local.oidc_discovery_url}",
		"OIDCScopes": [
			"openid",
			"profile",
			"email"
		],
		"ListClaimMappings": {
			"groups": "groups"
		},
		"VerboseOIDCLogging": true
	})
}

resource "consul_acl_binding_rule" "this" {
    auth_method = consul_acl_auth_method.oidc.name
    selector    = "consul_admins in list.groups"
    bind_type   = "role"
    bind_name   = "consul_admins"

}

resource "consul_acl_policy" "this" {
  name        = "consul_admins"
  datacenters = ["dc1"]
  rules       = <<-EOF
    node_prefix "" {
      policy = "read"
    }
    EOF
}

resource "consul_acl_role" "this" {
    name = "consul_admins"

    policies = [
        consul_acl_policy.this.id
    ]
}

# {
# 	"modules": [
# 		"global-visibility-routing-scale",
# 		"governance-policy"
# 	],
# 	"features": {
# 		"Add": ["sso"]
# 	}
# }