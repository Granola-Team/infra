output "kms_key" {
  description = "The KMS customer master key to encrypt state buckets."
  value       = aws_kms_key.state_key
}

output "kms_key_alias" {
  description = "The alias of the KMS customer master key used to encrypt state bucket and dynamodb."
  value       = aws_kms_alias.state_key_alias
}

output "state_bucket" {
  description = "The S3 bucket to store the remote state file."
  value       = aws_s3_bucket.state
}

output "dynamodb_table" {
  description = "The DynamoDB table to manage lock states."
  value       = aws_dynamodb_table.state_lock
}

output "terraform_iam_policy" {
  description = "The IAM Policy to access remote state environment."
  value       = aws_iam_policy.terraform_policy
}
