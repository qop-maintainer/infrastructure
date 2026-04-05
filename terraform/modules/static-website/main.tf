locals {
  target_domain   = var.apex_domain
  www_subdomain   = "www.${local.target_domain}"
  friendly_domain = replace(local.target_domain, ".", "-")
  origin_id       = "s3-${local.target_domain}"
}

data "aws_route53_zone" "existing" {
  name         = var.apex_domain
  private_zone = false
}

resource "aws_acm_certificate" "certificate" {
  provider                  = aws.cloudfront
  domain_name               = local.target_domain
  subject_alternative_names = [local.www_subdomain]
  validation_method         = "DNS"
}

resource "aws_route53_record" "validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id         = data.aws_route53_zone.existing.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "validation" {
  provider        = aws.cloudfront
  certificate_arn = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [
    for record in aws_route53_record.validation_records : record.fqdn
  ]
}

resource "aws_s3_bucket" "website" {
  provider = aws.cloudfront
  bucket   = local.friendly_domain
}

resource "aws_s3_bucket_public_access_block" "website" {
  provider = aws.cloudfront
  bucket   = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  provider = aws.cloudfront
  bucket   = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Disabled" # instead, redploy and fail forward
  }
}

resource "aws_cloudfront_origin_access_control" "oac_on_bucket" {
  provider                          = aws.cloudfront
  name                              = "${local.friendly_domain}-website-oac"
  description                       = "CloudFront OAC for ${local.friendly_domain} bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudfront_only" {
  provider = aws.cloudfront
  bucket   = aws_s3_bucket.website.id
  policy   = data.aws_iam_policy_document.allow_access_from_cloudfront_only.json
}

data "aws_iam_policy_document" "allow_access_from_cloudfront_only" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.website.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }
}

resource "aws_cloudfront_cache_policy" "cache_policy" {
  provider = aws.cloudfront

  name        = "${local.friendly_domain}-cache-policy"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_response_headers_policy" "response_headers" {
  provider = aws.cloudfront
  name     = "${local.friendly_domain}-security-headers"
  security_headers_config {
    # Content security policy specified via Astro meta tags, so not set here
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "fullscreen=(self)"
      override = true
    }
    items {
      header   = "Cross-Origin-Embedder-Policy"
      value    = "require-corp"
      override = true
    }
    items {
      header   = "Cross-Origin-Opener-Policy"
      value    = "same-origin"
      override = true
    }
    items {
      header   = "Cross-Origin-Resource-Policy"
      value    = "same-site"
      override = true
    }
    items {
      header   = "Server"
      value    = "Porridge Not Petrol"
      override = true
    }

  }
}

resource "aws_cloudfront_distribution" "distribution" {
  provider            = aws.cloudfront
  aliases             = [local.target_domain, local.www_subdomain]
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.certificate.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_on_bucket.id
  }
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = local.origin_id
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = aws_cloudfront_cache_policy.cache_policy.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.response_headers.id
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.apex_redirect.arn
    }
    compress = true
  }
  tags = {
    Name = local.target_domain
  }
}

resource "aws_route53_record" "subdomain" {
  zone_id = data.aws_route53_zone.existing.zone_id
  name    = local.www_subdomain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex" {
  zone_id = data.aws_route53_zone.existing.zone_id
  name    = local.target_domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}