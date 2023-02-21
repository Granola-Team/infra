resource "aws_kms_key" "ecr_key" {
  description         = "The KMS customer master key to encrypt the ecr repo."
  enable_key_rotation = true
}

resource "aws_kms_alias" "ecr_key_alias" {
  name          = "alias/ecr-key-${var.environment}"
  target_key_id = aws_kms_key.ecr_key.key_id
}
