resource "aws_iam_role" "create_user_conf" {
  name = "${local.name}-create-user-conf"
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

resource "aws_iam_policy" "create_user_conf" {
  policy = <<POLICY
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ssm:GetParameter"
            ],
            "Resource": [
              "arn:aws:ssm:${local.region}:${(local.account)}:parameter/${var.prefix}*"
            ]
        },
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

resource "aws_iam_role_policy_attachment" "create_user_conf" {
  policy_arn = aws_iam_policy.create_user_conf.arn
  role       = aws_iam_role.create_user_conf.name
}


module "create_user_conf" {
  source          = "terraform-aws-modules/lambda/aws"
  version         = "2.7.0"
  create_package  = true
  create_role     = false
  create          = true
  create_layer    = false
  create_function = true
  publish         = true
  function_name   = "${local.name}-create-user-conf"
  runtime         = "python3.9"
  handler         = "app.handler"
  memory_size     = 512
  timeout         = 30
  lambda_role     = aws_iam_role.create_user_conf.arn
  package_type    = "Zip"
  source_path     = "${path.module}/lambdas/user_conf"
  environment_variables = {
    WG_SSM_USERS_PREFIX = local.wg_ssm_user_prefix
    WG_SSM_CONFIG_PATH  = local.wg_ssm_config
    IAM_WG_GROUP_NAME   = var.wg_group_name
  }
}


