locals {
  repository_default_branch_name                 = coalesce(var.override_repository_default_branch_name, "main")
  iam_role_name_deploy                           = coalesce(var.override_iam_role_name_deploy, "gha-tf-deploy-${substr(var.github_repository, 0, 64 - length("gha-tf-deploy-"))}")
  github_env_var_name_iam_role_deploy_arn        = "AWS_IAM_ROLE_DEPLOY"
  github_env_var_name_bucket_name                = "AWS_S3_BUCKET_NAME"
  github_env_var_name_cloudfront_distribution_id = "AWS_CLOUDFRONT_DISTRIBUTION_ID"
  github_env_var_name_aws_region                 = "AWS_REGION"

  aws_tags = coalesce(var.override_aws_tags, {
    GitHubRepo = "${var.github_owner}/${var.github_repository}"
    Module     = "./modules/static-website-gha-cicd"
  })

  # https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  github_cert_thumbprint = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# Set up access from GitHub into the account. The thumbprint for GitHub
# certificate can be used from the post
# https://github.blog/changelog/2022-01-13-github-actions-update-on-oidc-based-deployments-to-aws/
# or generated.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  thumbprint_list = local.github_cert_thumbprint
  tags            = local.aws_tags
  client_id_list  = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "github_actions_write_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Condition to limit to default AWS OIDC audience
    # see: https://github.com/aws-actions/configure-aws-credentials?tab=readme-ov-file#oidc-audience
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Condition to limit to deploys to the production environment of the specific repository
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}/${var.github_repository}:environment:production",
      ]
    }
  }
}

# Role to allow GitHub actions to use this AWS account
resource "aws_iam_role" "github_actions_deploy" {
  name               = local.iam_role_name_deploy
  assume_role_policy = data.aws_iam_policy_document.github_actions_write_assume_role_policy.json
  tags               = local.aws_tags
}

data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid = "DeployContent"

    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*",
      "arn:aws:s3:::${var.bucket_name}"
    ]
  }
  statement {
    sid = "InvalidateCache"

    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      var.cloudfront_distribution_arn
    ]
  }
}

resource "aws_iam_policy" "github_actions_deploy_policy" {
  name        = "${local.iam_role_name_deploy}-policy"
  description = "Policy for GitHub Actions to deploy static website content and invalidate CloudFront cache"
  policy      = data.aws_iam_policy_document.github_actions_deploy.json
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy_policy" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_deploy_policy.arn
}

# Environment for 'production' configured manually in GitHub repo settings, with secrets created by Terraform below

resource "github_actions_environment_secret" "iam_policy_deploy_changes_name" {
  repository      = var.github_repository
  environment     = "production"
  secret_name     = local.github_env_var_name_iam_role_deploy_arn
  plaintext_value = aws_iam_role.github_actions_deploy.arn
}

resource "github_actions_environment_secret" "s3_bucket_name" {
  repository      = var.github_repository
  environment     = "production"
  secret_name     = local.github_env_var_name_bucket_name
  plaintext_value = "s3://${var.bucket_name}"
}

resource "github_actions_environment_secret" "cloudfront_distribution_id" {
  repository      = var.github_repository
  environment     = "production"
  secret_name     = local.github_env_var_name_cloudfront_distribution_id
  plaintext_value = var.cloudfront_distribution_id
}

resource "github_actions_variable" "aws_region" {
  repository    = var.github_repository
  variable_name = local.github_env_var_name_aws_region
  value         = var.aws_region
}
