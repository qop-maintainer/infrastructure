terraform {
  required_version = "1.14.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.23.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.7.0"
    }
  }
}