resource "aws_cognito_user_pool_client" "this" {
  for_each = local.config.client

  name = each.key

  user_pool_id  = aws_cognito_user_pool.this.id
  callback_urls = each.value.callback_urls
  # logout_urls - (Optional) List of allowed logout URLs for the identity providers.
  generate_secret              = false
  supported_identity_providers = ["COGNITO"]

  allowed_oauth_flows  = ["code"]            // (code, implicit, client_credentials).
  allowed_oauth_scopes = ["openid", "email"] //- (Optional) List of allowed OAuth scopes (phone, email, openid, profile, and aws.cognito.signin.user.admin).

  # allowed_oauth_flows_user_pool_client - (Optional) Whether the client is allowed to follow the OAuth protocol when interacting with Cognito user pools.
  # default_redirect_uri - (Optional) The default redirect URI. Must be in the list of callback URLs.
  # explicit_auth_flows - (Optional) List of authentication flows (ADMIN_NO_SRP_AUTH, CUSTOM_AUTH_FLOW_ONLY, USER_PASSWORD_AUTH).
  # refresh_token_validity - (Optional) The time limit in days refresh tokens are valid for.
  # read_attributes - (Optional) List of user pool attributes the application client can read from.
  # write_attributes - (Optional) List of user pool attributes the application client can write to.
}
