variable "cloudfront_distribution_arn" {
  description = "(Required) ARN of the CloudFront distribution to allow invalidations for"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "(Required) ID of the CloudFront distribution to allow invalidations for"
  type        = string
}
variable "bucket_name" {
  description = "(Required) Name of the S3 bucket hosting the static website"
  type        = string
}

variable "github_owner" {
  description = "(Required) Name of the GitHub owner"
  type        = string
}

variable "github_repository" {
  description = "(Required) The name of the GitHub repository to use"
  type        = string
}

variable "aws_region" {
  description = "(Required) AWS region to use"
  type        = string
}

variable "override_repository_default_branch_name" {
  description = "(Optional) Override the default branch name, defaults to main"
  type        = string
  default     = null
}

variable "override_iam_role_name_deploy" {
  description = "(Optional) Override the IAM role name used by the GitHub Actions workflows for website deploy, defaults to gh-tf-deploy-<repo_name>"
  type        = string
  default     = null
}

variable "override_aws_tags" {
  description = "(Optional) Override tags to apply to AWS resources"
  type        = map(string)
  default     = null
}
