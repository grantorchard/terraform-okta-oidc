locals {
  groups_claim = defaults(var.groups_claim, {
    type = "FILTER"
    filter_type = "CONTAINS"
	})
}

variable "auth_server_name" {
  type    = string
  default = ""
}

variable "auth_server_description" {
  type    = string
  default = "Auth server for OIDC connections."
}

variable "auth_server_audiences" {
  type    = list(string)
  default = ["api://vault"]
}

variable "auth_server_issuer_mode" {
  type    = string
  default = "ORG_URL"
  validation {
    condition     = var.auth_server_issuer_mode == "ORG_URL" || var.auth_server_issuer_mode == "CUSTOM_URL"
    error_message = "The supported values for the auth_server_issuer_mode variable are ORG_URL or CUSTOM_URL."
  }
}

variable "auth_server_status" {
  type    = string
  default = "ACTIVE"
  validation {
    condition     = var.auth_server_status == "ACTIVE" || var.auth_server_status == "INACTIVE"
    error_message = "The supported values for the status variable are ACTIVE on INACTIVE."
  }
}

variable "auth_server_policy_name" {
  type    = string
  default = ""
}

variable "auth_server_policy_description" {
  type    = string
  default = "Auth server policy for OIDC connections."
}

variable "auth_server_policy_status" {
  type    = string
  default = "ACTIVE"
  validation {
    condition     = var.auth_server_policy_status == "ACTIVE" || var.auth_server_policy_status == "INACTIVE"
    error_message = "The supported values for the status variable are ACTIVE on INACTIVE."
  }
}

variable "auth_server_policy_client_whitelist" {
  type    = list(string)
  default = ["ALL_CLIENTS"]
}

variable "auth_server_policy_rule_name" {
  type    = string
  default = ""
}

variable "auth_server_policy_rule_status" {
  type    = string
  default = "ACTIVE"
}

variable "auth_server_policy_rule_group_whitelist" {
  type    = list(string)
  default = ["EVERYONE"]
}

variable "app_oauth_grant_types" {
  type = list(string)
  default = [
    "authorization_code",
    "implicit"
  ]
}

variable "auth_server_policy_scope_whitelist" {
	type = list(string)
	default = [
		"openid",
		"email",
		"profile"
	]
}

variable "app_oath_label" {
  type    = string
  default = ""
}

variable "app_group_assignments" {
  type    = list(string)
  default = []
}

variable "groups_claim" {
	description = "Okta permits filtering the groups sent as part of the group claim. You can use this variable to specify one or more rules that be used to evaluate groups to be sent."
	type = list(object({
    type = optional(string)
    filter_type = optional(string)
    name = string
		value = string
	}))
}

# variable "server_claim" {
# 	description = "Allows dynamic access to the authorization server if a member of a provided group rule."
# 	type = list(object({
#     type = optional(string)
#     filter_type = optional(string)
#     name = string
# 		value = string
# 	}))
# }

variable "redirect_uris" {
  type        = list(string)
  description = "The URL to redirect the user back to after authentication succeeds."
  default     = []
}
