resource "aws_organizations_organization" "org" {
  feature_set = "ALL"

  aws_service_access_principals = [
    "iam.amazonaws.com",
    "sso.amazonaws.com",
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]
}

resource "aws_iam_organizations_features" "root_mgmt" {
  enabled_features = [
    "RootCredentialsManagement",
    "RootSessions"
  ]
}

resource "aws_organizations_organizational_unit" "production_ou" {
  name      = "Production"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_account" "production_account" {
  email     = "qop.maintainer+production@gmail.com"
  name      = "Production"
  role_name = "OrganizationAccountAccessRole"
  parent_id = aws_organizations_organizational_unit.production_ou.id

  lifecycle {
    ignore_changes = [role_name]
  }

  close_on_deletion = false
}
