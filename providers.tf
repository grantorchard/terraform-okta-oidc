terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 3.10"
    }
  }
	experiments = [module_variable_optional_attrs]
}