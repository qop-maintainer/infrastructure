#--------------------------------------------#
# Using locals instead of hard-coding strings
#--------------------------------------------#
locals {
  kms_key_alias = coalesce(var.override_kms_key_alias, "alias/aws/s3")

  aws_tags = coalesce(var.override_aws_tags, {
    Name   = "tf-bootstrap",
    Module = "modules/bootstrap-aws-account",
  })
}

#----------------------------------------------#
# AWS resources to store the state file
#----------------------------------------------#
# 1. S3 bucket, with versioning, KMS encryption,
#    no public access, and locked down ACLs

# S3 Bucket to store state file
resource "aws_s3_bucket" "state_file_bucket" {
  bucket = var.state_file_bucket_name
  tags   = local.aws_tags
}

# Guardrail to block public access to the S3 bucket ensured
resource "aws_s3_bucket_public_access_block" "state_file_bucket" {
  bucket = aws_s3_bucket.state_file_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Set ownership controls to bucket to prevent access from other AWS accounts
resource "aws_s3_bucket_ownership_controls" "state_file_bucket" {
  bucket = aws_s3_bucket.state_file_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Enable bucket versioning
resource "aws_s3_bucket_versioning" "state_file_bucket" {
  bucket = aws_s3_bucket.state_file_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_kms_alias" "s3" {
  name = local.kms_key_alias
}

# Encrypt bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "state_file_bucket" {
  bucket = aws_s3_bucket.state_file_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = data.aws_kms_alias.s3.target_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# IAM Policy document to access the S3 bucket used for the state file.
data "aws_iam_policy_document" "state_file_access_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.state_file_bucket.arn}",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.state_file_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      "${data.aws_kms_alias.s3.target_key_arn}",
    ]
  }

}

# State file access IAM policy - this will be used by other modules / resources
# that will be defined when this module is used.
resource "aws_iam_policy" "state_file_access_iam_policy" {
  name   = "tf-state-file-access"
  policy = data.aws_iam_policy_document.state_file_access_permissions.json
  tags   = local.aws_tags
}

# Create the terraform backend configuration - the catch 22 is that you need infrastructure to
# store the state file before you can automate your infrastructure. The approach needs 2 steps:
# 1. Create the S3 bucket to store the state, and generate the backend
#    config for terraform to use in the terraform.tf file.
# 2. For the 2nd run, it will now use this config and migrate the local state file to S3.
resource "local_file" "terraform_tf" {
  filename = "${path.root}/terraform.tf"
  content = templatefile("${path.module}/templates/terraform.tf.tmpl", {
    state_file_bucket_name = var.state_file_bucket_name
    state_file_bucket_key  = var.state_file_bucket_key
    state_file_aws_region  = var.state_file_aws_region
    kms_key_id             = local.kms_key_alias
    profile_name           = var.state_file_profile_name
  })
  directory_permission = "0755"
  file_permission      = "0644"
}
