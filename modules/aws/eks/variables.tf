variable "config" {
  type = object({
    vpc_id               = string
    subnet_ids           = list(string)
    cluster_version      = optional(string)
    master_api_sg        = optional(list(string))
    worker_node_count    = number
    worker_instance_type = string
    worker_volume_size   = number
    api_allowed_ips      = list(string)
    addons               = optional(list(string))
  })
}