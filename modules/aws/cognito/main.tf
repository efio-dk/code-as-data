locals {
  config = defaults(var.config, {
    enable_signup = false
  })
}
