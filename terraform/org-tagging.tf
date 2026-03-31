resource "aws_organizations_policy" "tagging_policy" {
  name        = "required-tags"
  description = "Enforce required tags across the organization"
  type        = "TAG_POLICY"

  content = jsonencode({
    tags = {
      Environment = {
        tag_key = {
          "@@assign" = "Environment"
        }
        tag_value = {
          "@@assign" = [
            "Production",
            "Management"
          ]
        }
        enforced_for = {
          "@@assign" = [
            "s3:bucket"
          ]
        }
      }
    }
  })
}

resource "aws_organizations_policy_attachment" "tagging_root" {
  policy_id = aws_organizations_policy.tagging_policy.id
  target_id = aws_organizations_organization.org.roots[0].id
}
