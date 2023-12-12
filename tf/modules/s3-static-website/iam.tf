data "aws_iam_policy_document" "cicd_policy" {

  statement {
    sid       = "${title(var.app_name)}CICDUser"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.main.arn}",
      "${aws_s3_bucket.main.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "cicd_user" {
    name = "${title(var.app_name)}CICDPolicy"
    description = "For the ${var.app_name} CI/CD user to upload and delete objects in the bucket"
    policy = data.aws_iam_policy_document.cicd_policy.json
}


