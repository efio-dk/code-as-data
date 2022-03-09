output "s3_bucket" {
  description = "The website S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "s3_website_domain" {
  description = "The website S3 bucket."
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}

output "kms_id" {
  description = "The id of the KMS Key."
  value       = aws_kms_key.this.id
}

output "cloudfront_id" {
  description = "The id of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.domain_name
}