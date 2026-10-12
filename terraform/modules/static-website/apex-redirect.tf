resource "aws_cloudfront_function" "apex_redirect" {
  provider = aws.cloudfront
  name     = "${local.friendly_domain}-apex-redirect"
  code     = file("${path.module}/functions/apex-redirect.js")
  comment  = "Redirects to apex domain from www subdomain"
  runtime  = "cloudfront-js-2.0"
  publish  = true
}
