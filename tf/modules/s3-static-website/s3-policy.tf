data "aws_iam_policy_document" "cicd_policy" {

  statement {
    sid       = "MinaSearchCICDUser"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.main.arn}",
      "${aws_s3_bucket.main.arn}/*",
    ]
  }
}

resource "aws_iam_user" "minasearch" {
  name = "minasearch"
}

resource "aws_iam_policy" "cicd_user" {
    name = "S3PutDeletePolicy"
    description = "For the minasearch CI/CD user to upload and delete objects in the bucket"
    policy = data.aws_iam_policy_document.cicd_policy.json
}

resource "aws_iam_user_policy_attachment" "user_attach" {
  user       = aws_iam_user.minasearch.name
  policy_arn = aws_iam_policy.cicd_user.arn
}


