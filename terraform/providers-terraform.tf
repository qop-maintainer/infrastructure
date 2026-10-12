provider "aws" {
  # profile = "qop_maintainer"
}

# Required manual creation of IAM user with permissions to assume the manually 
# created role using recovered root credentials, immediately deleted.
provider "aws" {
  alias  = "production"
  region = "eu-west-2"
  assume_role {
    role_arn    = "arn:aws:iam::530732072311:role/gha-tf-apply-infrastructure"
    external_id = "qop_maintainer"
  }
}

provider "aws" {
  alias  = "cloudfront"
  region = "us-east-1"
  assume_role {
    role_arn    = "arn:aws:iam::530732072311:role/gha-tf-apply-infrastructure"
    external_id = "qop_maintainer"
  }
}

