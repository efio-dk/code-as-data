locals {
  targets_map = { for t in flatten([
    for policy_name, policy in var.config.policies : [
      for target_name, target in policy.target : {
        policy_name = policy_name
        target_name = target_name
        target      = target.target
        target_type = target.target_type
    }]]) : "${t.policy_name}/${t.target_name}" => t
  }
}

resource "aws_organizations_policy" "this" {
  for_each = var.config.policies

  name    = each.key
  content = each.value.content
}

resource "aws_organizations_policy_attachment" "this" {
  for_each = local.targets_map

  policy_id = aws_organizations_policy.this[each.value.policy_name].id
  target_id = each.value.target_type == "ROOT" ? data.aws_organizations_organization.organization.roots[0].id : each.value.target_type == "UNIT" ? aws_organizations_organizational_unit.units[each.value.target].id : aws_organizations_account.accounts[each.value.target].id
}