output "bucket" {
  description = "Bucket where the website content is stored"
  value       = module.website.bucket
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket, used for CloudFront origin configuration"
  value       = module.website.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "Distribution ID of the CloudFront distribution serving the website"
  value       = module.website.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution serving the website"
  value       = module.website.cloudfront_distribution_arn
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution serving the website"
  value       = module.website.cloudfront_domain_name
}