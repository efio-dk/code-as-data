variable "default_tags" {
  description = "A map of default tags, that will be applied to all resources applicable."
  type        = map(string)
  default     = {}
}

variable "config" {
  description = ""
  type = object({
    name_prefix            = optional(string) # [a-z]
    domain_name            = string
    domain_alias           = optional(set(string))
    index_document         = optional(string)
    error_document         = optional(string)
    deploy_sample_document = optional(bool)
    allowed_ip_cidrs       = optional(set(string))
    cache_policy           = optional(string)
    acm_certificate_arn    = optional(string)
  })

}
