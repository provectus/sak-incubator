data "aws_region" "current" {}

locals {

  reuse_existing_acm_arn             = var.existing_acm_arn != ""
  create_self_signed_acm_certificate = var.existing_acm_arn == "" && var.self_sign_acm_certificate
  create_normal_acm_certificate      = var.existing_acm_arn == "" && !var.self_sign_acm_certificate

  aws_region = var.aws_region == "" ? data.aws_region.current.name : var.aws_region

}


provider "aws" {
  alias  = "certificate"
  region = local.aws_region
}



resource "aws_cloudwatch_log_group" "acm_cloudtrail_logs" {
  count = var.enable_cloudtrail_logging ? 1 : 0
  name  = "acm-cloudtrail-logs-${var.domain_name}"
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


resource "random_string" "role_suffix" {
  length  = 5
  special = false
}


resource "aws_s3_bucket" "acm_cloudtrail_logs" {

  count  = var.enable_cloudtrail_logging ? 1 : 0
  bucket = "acm-cloudtrail-logs-${var.domain_name}"
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
            "Resource": "acm-cloudtrail-logs-${var.domain_name}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "acm-cloudtrail-logs-${var.domain_name}/*",
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
  count = var.enable_cloudtrail_logging ? 1 : 0
  name  = "CloudWatchWriteForCloudTrail-${random_string.role_suffix.result}"

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


resource "aws_cloudtrail" "acm" {
  count                         = var.enable_cloudtrail_logging ? 1 : 0
  name                          = "acm-trail"
  s3_bucket_name                = aws_s3_bucket.acm_cloudtrail_logs[0].id
  s3_key_prefix                 = "trail"
  include_global_service_events = false


  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.acm_cloudtrail_logs[0].arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch[0].arn
}


# normal acm certificate
module "acm_certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "v2.0"

  count                     = local.create_normal_acm_certificate ? 1 : 0
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  zone_id                   = var.zone_id
  validate_certificate      = var.validate_certificate

  providers = {
    aws = aws.certificate
  }

  tags = var.tags
}



# self-signed certificate
resource "tls_private_key" "self_signed_cert" {
  count     = local.create_self_signed_acm_certificate ? 1 : 0
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "self_signed_cert" {
  count           = local.create_self_signed_acm_certificate ? 1 : 0
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.self_signed_cert[0].private_key_pem

  subject {
    common_name  = var.domain_name
    organization = var.domain_name
  }

  validity_period_hours = var.self_signed_certificate_validity_period

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "self_signed_cert" {
  count            = local.create_self_signed_acm_certificate ? 1 : 0
  private_key      = tls_private_key.self_signed_cert[0].private_key_pem
  certificate_body = tls_self_signed_cert.self_signed_cert[0].cert_pem

  provider = aws.certificate

}