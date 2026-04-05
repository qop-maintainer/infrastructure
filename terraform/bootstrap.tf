module "bootstrap" {
  source = "./modules/bootstrap-aws-account"

  state_file_aws_region  = "eu-west-2"
  state_file_bucket_name = "qop-maintainer-terraform-state-eu-west-2"
}

module "baseline" {
  source = "./modules/baseline-aws-account"
}

module "baseline_production" {
  source = "./modules/baseline-aws-account"
  providers = {
    aws = aws.production
  }
}

module "cicd" {
  source = "./modules/bootstrap-gha-cicd"

  github_owner              = "qop-maintainer"
  github_repository         = "infrastructure"
  aws_region                = "eu-west-2"
  state_file_iam_policy_arn = module.bootstrap.state_file_iam_policy_arn
}

module "website" {
  source = "./modules/static-website"

  providers = {
    aws.cloudfront = aws.cloudfront
    aws.production = aws.production
  }

  apex_domain = aws_route53_zone.qop.name
}

module "deploy_website" {
  source = "./modules/static-website-gha-cicd"

  providers = {
    aws = aws.production
  }
  github_owner                = "qop-maintainer"
  github_repository           = "queensofpain.cc"
  bucket_name                 = module.website.bucket
  cloudfront_distribution_arn = module.website.cloudfront_distribution_arn
  cloudfront_distribution_id  = module.website.cloudfront_distribution_id
  aws_region                  = "us-east-1"
}
