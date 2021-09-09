# Note that the inclusion of the Okta provider block here is only
# required since we use Okta resources in the root module.

terraform {
  required_providers {
    consul = {
      source = "hashicorp/consul"
      version = "2.13.0"
    }
		okta = {
      source  = "okta/okta"
      version = "~> 3.10"
    }
  }
}