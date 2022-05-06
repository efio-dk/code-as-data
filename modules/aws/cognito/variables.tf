variable "config" {
  description = ""
  type = object({
    domain          = string
    certificate_arn = optional(string)
    enable_signup   = optional(bool)
    client = map(object({
      callback_urls = set(string)
    }))
  })
}
