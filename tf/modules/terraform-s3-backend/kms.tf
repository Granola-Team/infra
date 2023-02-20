resource "aws_kms_key" "state_key" {
  description         = "This key is used to encrypt the terraform state bucket and dynamodb table"
  enable_key_rotation = true
}

resource "aws_kms_alias" "state_key_alias" {
  name          = "alias/state-key-${var.environment}"
  target_key_id = aws_kms_key.state_key.key_id
}
