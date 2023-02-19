resource "aws_dynamodb_table" "state_lock" {
  name     = "granola-tfstate-lock-${var.environment}"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = var.dynamodb_enable_server_side_encryption
    kms_key_arn = aws_kms_key.state_key.arn
  }

  point_in_time_recovery {
    enabled = true
  }
}
