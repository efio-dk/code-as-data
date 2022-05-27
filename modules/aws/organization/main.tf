data "aws_region" "current" {}

data "aws_organizations_organization" "organization" {}

locals {
  config = var.config

  master_account_id = tolist(setsubtract(data.aws_organizations_organization.organization.accounts, data.aws_organizations_organization.organization.non_master_accounts))[0].id

  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  inline_policies_map = { for k, ps in local.config.permission_sets : k => ps.inline_policy if ps.inline_policy != null }
  managed_policy_map  = { for k, ps in local.config.permission_sets : k => ps.policy_attachments if ps.policy_attachments != null ? length(ps.policy_attachments) > 0 : false }
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

  assignment_map = local.config.account_assignments != null ? {
    for a in local.config.account_assignments :
    format("%v-%v-%v-%v", a.account_id != null ? a.account_id : a.account, substr(a.principal_type, 0, 1), a.principal_name, a.permission_set) => a
  } : {}
  group_list = toset([for mapping in local.config.account_assignments : mapping.principal_name if mapping.principal_type == "GROUP"])
  user_list  = toset([for mapping in local.config.account_assignments : mapping.principal_name if mapping.principal_type == "USER"])

  targets_map = local.config.policies != null ? { for t in flatten([
    for policy_name, policy in local.config.policies : [
      for target_name, target in policy.targets : {
        policy_name = policy_name
        target_name = target_name
        target      = target.target
        target_type = target.target_type
    }]]) : "${t.policy_name}/${t.target_name}" => t 
  } : {}

  cloudtrail_name    = local.config.cloudtrail_name != null ? local.config.cloudtrail_name : "cloudtrail"
  cloudtrail_s3_name = local.config.cloudtrail_s3_name != null ? local.config.cloudtrail_s3_name : "s3-cloudtrail"
}