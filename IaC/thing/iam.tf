data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["iot.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

//TODO
data "aws_iam_policy_document" "this" {
  statement {
    effect    = "Allow"
    actions   = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["${var.s3_bucket_arn}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test = "StringLike"
      variable = "cloudwatch:namespace"
      values = ["IOT"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["timestream:WriteRecords"]
    resources = var.table_arns
  }

  statement {
    effect    = "Allow"
    actions   = ["timestream:DescribeEndpoints"]
    resources = ["*"]
  }
}



resource "aws_iam_role_policy" "this" {
  name   = var.name
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}