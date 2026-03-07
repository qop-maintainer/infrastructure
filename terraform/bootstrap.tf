module "bootstrap" {
    source = "./modules/bootstrap-aws-account"

    state_file_aws_region  = "eu-west-2"
    state_file_bucket_name = "qop-maintainer-terraform-state-eu-west-2"
}