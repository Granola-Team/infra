output "ecr_repo" {
  description = "The ECR repository url"
  value       = aws_ecr_repository.repository_url
}

output "kms_key" {
  description = "The KMS customer master key to encrypt the ecr repo."
  value       = aws_kms_key.ecr_key
}

output "kms_key_alias" {
  description = "The alias of the KMS customer master key used to encrypt the ecr repo."
  value       = aws_kms_alias.ecr_key_alias
}

output "ecr_iam_policy" {
  description = "The IAM Policy to access the ECR repository."
  value       = aws_iam_policy.ecr_policy
}
