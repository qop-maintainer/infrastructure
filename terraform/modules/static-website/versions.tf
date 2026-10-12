terraform {
  required_version = "~> 1.14"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.34"
      configuration_aliases = [aws.cloudfront, aws.production]
    }
  }
}
