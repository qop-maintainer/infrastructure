# Ensure that reasonable password policies are in place for IAM users
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 45
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  password_reuse_prevention      = 15
  max_password_age               = 45
  allow_users_to_change_password = true
}

# Ensure that EBS volumes are encrypted by default
resource "aws_ebs_encryption_by_default" "primary_region" {
  enabled = true
}

# Ensure that S3 buckets are private by default, and that public ACLs and policies are blocked
resource "aws_s3_account_public_access_block" "strict" {
  block_public_acls   = true
  block_public_policy = true
}

# Adopt the default VPC and security group, with the side effect of deleting the default
# ingress and egress rules, which are too permissive for our use case
resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}
