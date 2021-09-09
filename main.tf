locals {
  issuer = regex("^(.*?).com/", okta_auth_server.this.issuer)
}

## Random naming function
resource "random_pet" "this" {
  length = 2
}

resource "random_integer" "this" {
  min = 10000
  max = 99999
}

resource "okta_auth_server" "this" {
  audiences   = var.auth_server_audiences
  description = var.auth_server_description
  name        = var.auth_server_name != "" ? var.auth_server_name : "${random_pet.this.id}-${random_integer.this.result}"
  issuer_mode = upper(var.auth_server_issuer_mode)
  status      = upper(var.auth_server_status)
}

resource "okta_auth_server_policy" "this" {
  auth_server_id   = okta_auth_server.this.id
  status           = var.auth_server_policy_status
  name             = var.auth_server_policy_name != "" ? var.auth_server_policy_name : "${random_pet.this.id}-${random_integer.this.result}"
  description      = var.auth_server_policy_description
  priority         = 1
  client_whitelist = var.auth_server_policy_client_whitelist
}

resource "okta_auth_server_policy_rule" "this" {
  auth_server_id  = okta_auth_server.this.id
  policy_id       = okta_auth_server_policy.this.id
  status          = var.auth_server_policy_rule_status
  name            = var.auth_server_policy_rule_name != "" ? var.auth_server_policy_name : "${random_pet.this.id}-${random_integer.this.result}"
  priority        = 1
  group_whitelist = var.auth_server_policy_rule_group_whitelist
  grant_type_whitelist = [
    "authorization_code",
    "implicit"
  ]
  scope_whitelist = var.auth_server_policy_scope_whitelist
}

resource "okta_auth_server_claim" "this" {
	for_each = { for claim in var.groups_claim: claim.value => claim }

	auth_server_id    = okta_auth_server.this.id
	name              = "${each.value.value}_members"
	group_filter_type = upper(each.value.filter_type)
	value_type        = "GROUPS"
	value             = each.value.value
	scopes            = ["profile"]
	claim_type        = "IDENTITY"
}

resource "okta_app_oauth" "this" {
  label         = var.app_oath_label != "" ? var.app_oath_label : "${random_pet.this.id}-${random_integer.this.result}"
  type          = "web"
  grant_types   = var.app_oauth_grant_types
  redirect_uris = var.redirect_uris
  response_types = [
    "id_token",
    "code"
  ]
  dynamic "groups_claim" {
		for_each = var.groups_claim
		content {
			type        = upper(groups_claim.value.type)
			name        = groups_claim.value.name
			filter_type = upper(groups_claim.value.filter_type)
			value       = groups_claim.value.value
  	}
	}
	# This lifecycle block is needed because we are assigning access to the app via
	# the okta_app_group_assignments resource.
	lifecycle {
		ignore_changes = [
			 groups
		]
  }
}

resource "okta_app_oauth_api_scope" "this" {
  app_id = okta_app_oauth.this.id
  issuer = "${regex("^(.*?).com/", okta_auth_server.this.issuer)[0]}.com"
  scopes = sort(["okta.users.read.self", "okta.groups.read"])
}

resource "okta_app_group_assignments" "this" {
  app_id = okta_app_oauth.this.id
  dynamic "group" {
    for_each = var.app_group_assignments
    content {
      id = group.value
    }
  }
}