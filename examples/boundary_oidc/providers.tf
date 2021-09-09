terraform {
  required_providers {
    boundary = {
			source = "localhost/providers/boundary"
			version = "0.0.1"
		}
    okta = {
      source  = "okta/okta"
      version = "~> 3.10"
    }
  }
}