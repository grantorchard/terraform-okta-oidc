output "client_id" {
  value = okta_app_oauth.this.client_id
}

output "client_secret" {
  value = okta_app_oauth.this.client_secret
}

output "issuer" {
  value = okta_auth_server.this.issuer
}