terraform {
  required_version = "~> 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.34"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.11"
    }
  }
}
