output "website_bucket_name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_endpoint" {
  description = "Bucket endpoint"
  value       = aws_s3_bucket_website_configuration.main.website_endpoint
}

output "cloudfront_distribution" {
    description = "CloudFront distribution"
    value       = aws_cloudfront_distribution.dist.domain_name
}

output "access_key_id" {
    description = "the AWS access key id for the CI/CD user"
    value = aws_iam_access_key.secrets.id
}

output "encypted_secret_access_key" {
    description = "Encyrpted AWS secret access key"
    value = aws_iam_access_key.secrets.encrypted_secret
}