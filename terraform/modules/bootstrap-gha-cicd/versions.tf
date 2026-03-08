terraform {
  required_version = "1.14.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.34.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.11.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.7.0"
    }
  }
}