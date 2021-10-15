resource "aws_iam_role" "send_wg_conf" {
  name = "${local.name}-send-wg-conf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "send_wg_conf" {
  policy = <<POLICY
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
            "ec2:DescribeNetworkInterfaces",
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeInstances",
            "ec2:AttachNetworkInterface"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_policy" "send_wg_conf_ses" {
  count = var.wg_admin_email != null ? 1 : 0
  policy = <<POLICY
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendRawEmail"
            ],
            "Resource": "arn:aws:ses:${local.region}:${local.account}:identity/${var.wg_admin_email}"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "send_wg_conf_ses" {
  count = var.wg_admin_email != null ? 1 : 0
  policy_arn = aws_iam_policy.send_wg_conf_ses[0].arn
  role       = aws_iam_role.send_wg_conf.name
}

resource "aws_iam_role_policy_attachment" "send_wg_conf" {
  policy_arn = aws_iam_policy.send_wg_conf.arn
  role       = aws_iam_role.send_wg_conf.name
}


module "send_wg_conf" {
  source          = "terraform-aws-modules/lambda/aws"
  version         = "2.7.0"
  create_package  = true
  create_role     = false
  create          = var.wg_admin_email != null ? true : false
  create_layer    = false
  create_function = true
  publish         = true
  function_name   = "${local.name}-send-wg-conf"
  runtime         = "python3.9"
  handler         = "app.handler"
  memory_size     = 512
  timeout         = 30
  lambda_role     = aws_iam_role.send_wg_conf.arn
  package_type    = "Zip"
  source_path     = "${path.module}/lambdas/send-wg-conf"
  environment_variables = {
    WG_ADMIN_EMAIL = var.wg_admin_email
    LOCAL_NAME = local.name
  }
}


