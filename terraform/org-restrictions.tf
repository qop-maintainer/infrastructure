# Deny any account from leaving the organization
resource "aws_organizations_policy" "deny_leave_org" {
  name        = "deny-leave-organization"
  description = "Denies accounts from leaving the AWS Organization"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyLeaveOrganization"
        Effect   = "Deny"
        Action   = "organizations:LeaveOrganization"
        Resource = "*"
      }
    ]
  })
}

# Deny usage of the root user in member accounts
resource "aws_organizations_policy" "deny_root_user" {
  name        = "deny-root-user-actions"
  description = "Denies the use of root user credentials in member accounts"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyRootUserActions"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }
    ]
  })
}

# Deny actions outside approved regions
resource "aws_organizations_policy" "restrict_regions" {
  name        = "restrict-regions"
  description = "Denies AWS usage outside of approved regions"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyUnapprovedRegions"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "us-east-1",
              "eu-west-2"
            ]
          }
          ArnNotLike = {
            "aws:PrincipalArn" = [
              "arn:aws:iam::*:role/OrganizationAccountAccessRole"
            ]
          }
        }
      }
    ]
  })
}

# Deny disabling critical security services
resource "aws_organizations_policy" "protect_security_services" {
  name        = "protect-security-services"
  description = "Denies disabling CloudTrail, GuardDuty, Config, and SecurityHub"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ProtectCloudTrail"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
        ]
        Resource = "*"
      },
      {
        Sid    = "ProtectGuardDuty"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
        ]
        Resource = "*"
      },
      {
        Sid    = "ProtectConfig"
        Effect = "Deny"
        Action = [
          "config:StopConfigurationRecorder",
          "config:DeleteConfigurationRecorder",
        ]
        Resource = "*"
      },
      {
        Sid    = "ProtectSecurityHub"
        Effect = "Deny"
        Action = [
          "securityhub:DisableSecurityHub",
          "securityhub:DeleteMembers",
        ]
        Resource = "*"
      }
    ]
  })
}

# Limit which services the Production account can use
resource "aws_organizations_policy" "restrict_expensive_services" {
  name        = "production-service-restrictions"
  description = "Restricts expensive or sensitive services in production accounts"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyExpensiveServices"
        Effect = "Deny"
        Action = [
          "redshift:*",
          "emr:*",
          "es:*",
          "dms:*",
          "directconnect:*",
        ]
        Resource = "*"
      },
      {
        Sid      = "DenyInstances"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringNotLike = {
            "ec2:InstanceType" = [
              "t*.micro",
              "t*.nano",
            ]
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "deny_leave_org_root" {
  policy_id = aws_organizations_policy.deny_leave_org.id
  target_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_policy_attachment" "deny_root_user_all" {
  policy_id = aws_organizations_policy.deny_root_user.id
  target_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_policy_attachment" "restrict_regions_workloads" {
  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = aws_organizations_organizational_unit.production_ou.id
}

resource "aws_organizations_policy_attachment" "protect_security_all" {
  policy_id = aws_organizations_policy.protect_security_services.id
  target_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_policy_attachment" "restrict_expensive_services" {
  policy_id = aws_organizations_policy.restrict_expensive_services.id
  target_id = aws_organizations_organizational_unit.production_ou.id
}
