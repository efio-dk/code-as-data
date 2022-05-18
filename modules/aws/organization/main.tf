locals {
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  inline_policies_map = { for k, ps in var.config.permission_sets : k => ps.inline_policy if ps.inline_policy != null }
  managed_policy_map  = { for k, ps in var.config.permission_sets : k => ps.policy_attachments if length(ps.policy_attachments) > 0 }
  managed_policy_attachments = flatten([     
    for ps_name, policy_list in local.managed_policy_map : [
      for policy in policy_list : {
        policy_set = ps_name
        policy_arn = policy
      }
    ]
  ])
  managed_policy_attachments_map = {
    for policy in local.managed_policy_attachments : "${policy.policy_set}.${policy.policy_arn}" => policy
  }

  assignment_map = {
    for a in var.config.account_assignments :
    format("%v-%v-%v-%v", a.account, substr(a.principal_type, 0, 1), a.principal_name, a.permission_set) => a
  }
  group_list = toset([for mapping in var.config.account_assignments : mapping.principal_name if mapping.principal_type == "GROUP"])
  user_list  = toset([for mapping in var.config.account_assignments : mapping.principal_name if mapping.principal_type == "USER"])
}
