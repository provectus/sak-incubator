resource "aws_cloudwatch_log_group" "s3_cloudtrail_logs" {
  count = var.s3_cloudwatch_logging_enabled ? 1 : 0
  name  = "s3-cloudtrail-logs-${var.s3_bucket_name}"
}

data "aws_iam_policy_document" "cloudtrail-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}



resource "aws_s3_bucket" "s3_cloudtrail_logs" {

  count  = var.s3_cloudwatch_logging_enabled ? 1 : 0
  bucket = "s3-cloudtrail-logs-${var.s3_bucket_name}"
  tags   = var.tags

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::s3-cloudtrail-logs-${var.s3_bucket_name}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::s3-cloudtrail-logs-${var.s3_bucket_name}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}


resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  count = var.s3_cloudwatch_logging_enabled ? 1 : 0
  name  = "CloudWatchWriteForCloudTrail"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = data.aws_iam_policy_document.cloudtrail-assume-role-policy.json
  inline_policy {
    name = "cloudwatch_write_permissions"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "cloudwatch:PutMetricData",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups",
            "logs:CreateLogStream",
            "logs:CreateLogGroup"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_s3_bucket" "main" {

  bucket = var.s3_bucket_name
  tags   = var.tags

  # lifecycle {
  #   prevent_destroy = false
  # }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_cloudtrail" "s3" {
  count                         = var.s3_cloudwatch_logging_enabled ? 1 : 0
  name                          = "s3-bucket-trail"
  s3_bucket_name                = aws_s3_bucket.s3_cloudtrail_logs[0].id
  s3_key_prefix                 = "trail"
  include_global_service_events = false


  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.main.arn}/"]
    }
  }

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.s3_cloudtrail_logs[0].arn}:*" # CloudTrail requires the Log Stream wildcard
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch[0].arn
}


// create read-write user for S3 bucket
resource "aws_iam_user" "s3_user" {
  name = "${var.cluster_name}-s3-user"
  path = "/system/"
}

resource "aws_iam_access_key" "s3_user" {
  user = aws_iam_user.s3_user.name
}

resource "aws_iam_user_policy" "s3_user" {
  name = "${var.cluster_name}-s3-user-policy"
  user = aws_iam_user.s3_user.name

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["${aws_s3_bucket.main.arn}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": ["${aws_s3_bucket.main.arn}/*"]
        }
    ]
}

EOT
}

// create read-write role for S3 bucket




resource "aws_iam_policy" "s3_role" {
  name = "${var.cluster_name}-s3-role-policy"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["${aws_s3_bucket.main.arn}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": ["${aws_s3_bucket.main.arn}/*"]
        }
    ]
}
EOT
}

module "s3_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "3.0"

  trusted_role_arns = var.trusted_role_arns

  create_role = true

  role_name = "${var.cluster_name}-s3-role"

  role_requires_mfa = false

  custom_role_policy_arns = [
    aws_iam_policy.s3_role.arn
  ]

  number_of_custom_role_policy_arns = 1
  tags                              = var.tags
}




