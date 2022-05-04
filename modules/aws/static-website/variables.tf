variable "config" {
  description = ""
  type = object({
    domain_name         = string
    domain_alias        = optional(set(string))
    index_document      = optional(string)
    error_document      = optional(string)
    allowed_ip_cidrs    = optional(set(string))
    cache_policy        = optional(string)
    acm_certificate_arn = optional(string)
    disable_cloudfront  = optional(bool)
    kms_arn             = optional(string)
  })
}
