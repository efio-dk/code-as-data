resource "random_uuid" "external_id" {}

resource "aws_iam_role" "this" {
  name = "${local.name_prefix}cognito-role"
  tags = local.default_tags
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : ["cognito-idp.amazonaws.com"]
        },
        "Action" : "sts:AssumeRole"
        "Condition" : {
          "StringEquals" : {
            "sts:ExternalId" : random_uuid.external_id.result
          }
        }
      }
    ]
  })

  inline_policy {
    name = "codepipeline_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "sns:publish"
          ],
          "Resource" : [
            "*"
          ]
        }
      ]
    })
  }
}

resource "aws_cognito_user_pool" "this" {
  name = "${local.name_prefix}user-pool"
  tags = local.default_tags

  # Sign-in experience

  ## Cognito user pool sign-in

  # alias_attributes = ["phone_number", "email", "preferred_username"]
  username_attributes = ["phone_number", "email"]
  username_configuration {
    case_sensitive = false
  }

  ## Password policy
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  ## Multi-factor authentication
  mfa_configuration = local.config.optional_mfa ? "OPTIONAL" : "ON"
  software_token_mfa_configuration {
    enabled = true
  }

  ## User account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }

    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 2
    }

    # recovery_mechanism {
    #   name     = "admin_only"
    #   priority = 1
    # }
  }

  ## Device tracking
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  # Sign-up experience
  auto_verified_attributes = ["email", "phone_number"]
  admin_create_user_config {
    allow_admin_create_user_only = !local.config.enable_signup
    invite_message_template {
      email_subject = "Your temporary password"
      email_message = "Your username is {username} and temporary password is {####}."
      sms_message   = "Your username is {username} and temporary password is {####}."
    }
  }

  # Message delivery

  ## E-mail
  email_configuration {
    email_sending_account  = "COGNITO_DEFAULT" # COGNITO_DEFAULT|DEVELOPER
    source_arn             = null              # ARN of the SES verified email identity to to use.
    configuration_set      = null              # Email configuration set name from SES
    from_email_address     = null              # "John Smith <john@example.com>"
    reply_to_email_address = "john@example.com"
  }

  ## SMS
  sms_configuration {
    external_id    = random_uuid.external_id.result
    sns_caller_arn = aws_iam_role.this.arn
  }

  ## Message templates
  sms_authentication_message = "Your authentication code is {####}."
  verification_message_template {
    default_email_option  = "CONFIRM_WITH_CODE" # CONFIRM_WITH_LINKCONFIRM_WITH_CODE|CONFIRM_WITH_LINK
    email_subject         = "Your verification code"
    email_message         = "Your verification code is {####}."
    email_subject_by_link = "Your verification link"
    email_message_by_link = "Please click the link below to verify your email address. {##Verify Email##}"
    sms_message           = "Your verification code is {####}."
  }

  dynamic "schema" {
    for_each = { for k, v in local.config.schema : k => v if !contains(["Number", "String"], v.attribute_data_type) }

    content {
      name                     = schema.key
      attribute_data_type      = schema.value.attribute_data_type
      required                 = schema.value.required
      developer_only_attribute = schema.value.developer_only_attribute
      mutable                  = schema.value.mutable
    }
  }

  dynamic "schema" {
    for_each = { for k, v in local.config.schema : k => v if "String" == v.attribute_data_type }

    content {
      name                     = schema.key
      attribute_data_type      = schema.value.attribute_data_type
      required                 = schema.value.required
      developer_only_attribute = schema.value.developer_only_attribute
      mutable                  = schema.value.mutable

      string_attribute_constraints {
        max_length = schema.value.string_attribute_constraints != null ? schema.value.string_attribute_constraints.max_length : null
        min_length = schema.value.string_attribute_constraints != null ? schema.value.string_attribute_constraints.min_length : null
      }
    }
  }

  dynamic "schema" {
    for_each = { for k, v in local.config.schema : k => v if "Number" == v.attribute_data_type }

    content {
      name                     = schema.key
      attribute_data_type      = schema.value.attribute_data_type
      required                 = schema.value.required
      developer_only_attribute = schema.value.developer_only_attribute
      mutable                  = schema.value.mutable

      number_attribute_constraints {
        max_value = schema.value.number_attribute_constraints != null ? schema.value.number_attribute_constraints.max_value : null
        min_value = schema.value.number_attribute_constraints != null ? schema.value.number_attribute_constraints.min_value : null
      }
    }
  }

  # App integration
  # schema {#} - (Optional) Configuration block for the schema attributes of a user pool. Detailed below. Schema attributes from the standard attribute set only need to be specified if they are different from the default configuration. Attributes can be added, but not modified or removed. Maximum of 50 attributes.
  #   attribute_data_type - (Required) Attribute data type. Must be one of Boolean, Number, String, DateTime.
  #   developer_only_attribute - (Optional) Whether the attribute type is developer only.
  #   mutable - (Optional) Whether the attribute can be changed once it has been created.
  #   name - (Required) Name of the attribute.
  #   number_attribute_constraints - (Required when attribute_data_type is Number) Configuration block for the constraints for an attribute of the number type. Detailed below.
  #   required - (Optional) Whether a user pool attribute is required. If the attribute is required and the user does not provide a value, registration or sign-in will fail.
  #   string_attribute_constraints - (Required when attribute_data_type is String) Constraints for an attribute of the string type. Detailed below.
  # }
}

resource "aws_cognito_user_pool_domain" "this" {
  domain          = local.config.domain
  user_pool_id    = aws_cognito_user_pool.this.id
  certificate_arn = local.config.certificate_arn
}
