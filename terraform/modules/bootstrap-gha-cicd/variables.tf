variable "github_owner" {
  description = "(Required) Name of the GitHub owner"
  type        = string
}

variable "github_repository" {
  description = "(Required) The name of the GitHub repository to use"
  type        = string
}

variable "state_file_iam_policy_arn" {
  description = "(Required) ARN of IAM policy allowing access to the state file"
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

variable "override_iam_role_name_apply" {
  description = "(Optional) Override the IAM role name used by the GitHub Actions workflows for terraform apply, defaults to gh-tf-apply-<repo_name>"
  type        = string
  default     = null
}

variable "override_iam_policy_apply_arn" {
  description = "(Optional) Override the IAM policy ARN used by the GitHub Actions workflows for terraform apply, defaults to built-in policy/AdministratorAccess"
  type        = string
  default     = null
}

variable "override_iam_role_name_plan" {
  description = "(Optional) Override the IAM role name used by the GitHub Actions workflows for terraform plan, defaults to gh-tf-plan-<repo_name>"
  type        = string
  default     = null
}

variable "override_iam_policy_plan_arn" {
  description = "(Optional) Override the IAM policy ARN used by the GitHub Actions workflows for terraform plan, defaults to built-in policy/ReadOnlyAccess"
  type        = string
  default     = null
}

variable "override_aws_ssm_name_github_token" {
  description = "(Optional) Name of the SSM parameter to store the GitHub token, defaults to /cicd/github_token"
  type        = string
  default     = null
}

variable "override_aws_tags" {
  description = "(Optional) Override tags to apply to AWS resources"
  type        = map(string)
  default     = null
}
