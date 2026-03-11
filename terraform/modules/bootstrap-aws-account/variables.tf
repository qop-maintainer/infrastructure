
variable "state_file_bucket_name" {
  description = "(Required) Name of the S3 bucket to store the state file"
  type        = string
}

variable "state_file_bucket_key" {
  description = "(Required) Key of the S3 bucket to store the state file"
  type        = string
  default     = "terraform-state"
}

variable "state_file_aws_region" {
  description = "(Required) Region of the S3 bucket to store the state file"
  type        = string
}

variable "state_file_profile_name" {
  description = "(Optional) Name of the Profile to use for the state file S3 bucket"
  type        = string
  default     = null
}

variable "override_aws_tags" {
  description = "(Optional) Override tags to apply to AWS resources"
  type        = map(string)
  default     = null
}

variable "override_kms_key_alias" {
  description = "(Optional) Override KMS key alias to use for state file encryption, defaults to alias/aws/s3"
  type        = string
  default     = null
}
