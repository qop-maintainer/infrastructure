terraform {
  required_version = "1.14.6"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "2.7.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.36.0"
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
