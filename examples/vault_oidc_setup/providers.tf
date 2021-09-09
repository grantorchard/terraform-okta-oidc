terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "2.22.1"
    }
    okta = {
      source  = "okta/okta"
      version = "~> 3.10"
    }
  }
}