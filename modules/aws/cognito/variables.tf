variable "config" {
  description = ""
  type = object({
    domain          = string
    certificate_arn = optional(string)
    enable_signup   = optional(bool)
    schema = optional(map(object({
      attribute_data_type      = string
      required                 = optional(bool)
      developer_only_attribute = optional(bool)
      mutable                  = optional(bool)
      number_attribute_constraints = optional(object({
        max_value = optional(number)
        min_value = optional(number)
      }))
      string_attribute_constraints = optional(object({
        max_length = optional(number)
        min_length = optional(number)
      }))
    })))

    client = map(object({
      callback_urls = set(string)
      logout_urls   = set(string)
      auth_flows    = optional(set(string))
    }))
  })
}
