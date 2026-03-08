module "bootstrap" {
  source = "./modules/bootstrap-aws-account"

  state_file_aws_region  = "eu-west-2"
  state_file_bucket_name = "qop-maintainer-terraform-state-eu-west-2"

  tf_additional_providers = [{
    name             = "github"
    provider_source  = "integrations/github"
    provider_version = "6.11.1"
  }]
}

module "cicd" {
  source = "./modules/bootstrap-gha-cicd"

  github_owner              = "qop-maintainer"
  github_repository         = "infrastructure"
  aws_region                = "eu-west-2"
  state_file_iam_policy_arn = module.bootstrap.state_file_iam_policy_arn
}
