data "aws_iam_policy_document" "state" {
  statement {
    effect    = "Allow"
    actions   = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
    ]
    resources = [
      aws_s3_bucket.state.arn
    ]
  }

  statement {
    effect    = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.state.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
    ]
    resources = [
      aws_dynamodb_table.state_lock.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:ListKeys"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
    ]
    resources = [
      aws_kms_key.state_key.arn
    ]
  }
}

resource "aws_iam_role" "terraform_role" {
  name               = "terraform-role"
  assume_role_policy = data.aws_iam_policy_document.state.json
}
