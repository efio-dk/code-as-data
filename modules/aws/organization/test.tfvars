config = {
  units = ["ops", "config", "admin"]

  accounts = {
    billing = {
      email     = "admin+billing@acmecorp.com"
      role_name = "Admin"
    }
    stage = {
      email     = "admin+stage@acmecorp.com"
      role_name = "Admin"
      unit      = "ops"
    },
    prod = {
      email     = "admin+prod@acmecorp.com"
      role_name = "Admin"
      unit      = "ops"
    },
    config = {
      email     = "admin+config@acmecorp.com"
      role_name = "Admin"
      unit      = "config"
    },
    backup = {
      email     = "admin+backup@acmecorp.com"
      role_name = "Admin"
      unit      = "admin"
    }
  },

  permission_sets = {
    AdministratorAccess = {
      description        = "Allow Full Access to the account",
      policy_attachments = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    },
    ViewOnlyAccess = {
      policy_attachments = ["arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"]
    }
  }

  account_assignments = [
    {
      account        = "billing",
      permission_set = "AdministratorAccess",
      principal_type = "GROUP",
      principal_name = "Administrators"
    },
    {
      account        = "stage",
      permission_set = "AdministratorAccess",
      principal_type = "GROUP",
      principal_name = "Administrators"
    },
    {
      account        = "prod",
      permission_set = "AdministratorAccess",
      principal_type = "GROUP",
      principal_name = "Administrators"
    },
    {
      account        = "config",
      permission_set = "AdministratorAccess",
      principal_type = "GROUP",
      principal_name = "Administrators"
    },
    {
      account        = "backup",
      permission_set = "AdministratorAccess",
      principal_type = "GROUP",
      principal_name = "Administrators"
    }
  ]
}
