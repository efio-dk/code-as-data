variable "default_tags" {
  description = "A map of default tags, that will be applied to all resources applicable."
  type        = map(string)
  default     = {}
}

variable "config" {
  description = ""
  type = object({
    region  = optional(string)
    profile = optional(string)
    assume_role = optional(object({
      role_arn     = string
      session_name = string
      external_id  = string
    }))

    name_prefix     = optional(string) # [a-z]
    domain          = string
    certificate_arn = optional(string)
    enable_signup   = optional(bool)
    client = object({
      name          = string
      callback_urls = set(string)
    })
  })
}

