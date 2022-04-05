variable "default_tags" {
  description = "A map of default tags, that will be applied to all resources applicable."
  type        = map(string)
  default     = {}
}

variable "config" {
  description = ""
  type = object({
    name_prefix     = optional(string) # [a-z]
    domain          = string
    certificate_arn = optional(string)
    enable_signup   = optional(bool)
    client = map(object({
      callback_urls = set(string)
    }))
  })
}
