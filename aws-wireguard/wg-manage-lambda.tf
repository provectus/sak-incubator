resource "aws_iam_role" "wg_manage" {
  name = "${local.name}-wg-manage"
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

resource "aws_iam_policy" "wg_manage" {
  policy = <<POLICY
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ssm:PutParameter",
              "ssm:GetParameters",
              "ssm:GetParametersByPath",
              "ssm:DeleteParameter",
              "ssm:DescribeParameters",
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
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetGroup"
            ],
            "Resource": "arn:aws:iam::${local.account}:group${local.prefix}/${var.wg_group_name}"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:RebootInstances",
            "Resource": "${module.ec2_vpn_instance.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
              "sns:Subscribe",
              "sns:Receive"
            ],
            "Resource": "${aws_sns_topic.wireguard_group_change_notification.arn}"
        },
        {
            "Effect": "Allow",
            "Action": "lambda:InvokeFunction",
            "Resource": "arn:aws:lambda:${local.region}:${local.account}:function:${local.name}-send-wg-conf"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "wg_manage" {
  policy_arn = aws_iam_policy.wg_manage.arn
  role       = aws_iam_role.wg_manage.name
}

module "wg_manage" {
  source          = "terraform-aws-modules/lambda/aws"
  version         = "2.7.0"
  create_package  = false
  create_role     = false
  create          = true
  create_layer    = false
  create_function = true
  publish         = true
  function_name   = "${local.name}-wg-manage"
  memory_size     = 512
  timeout         = 30
  lambda_role     = aws_iam_role.wg_manage.arn
  package_type    = "Image"
  image_uri       = module.wg_manage_image.image_uri

  environment_variables = {
    WG_SSM_USERS_PREFIX    = local.wg_ssm_user_prefix
    WG_SSM_CONFIG_PATH     = local.wg_ssm_config
    IAM_WG_GROUP_NAME      = var.wg_group_name
    WG_SUBNET              = var.vpn_subnet
    WG_LISTEN_PORT         = var.listen-port
    WG_INSTANCE_ID         = local.wg_ssm_instance_id
    WG_PUBLIC_IP           = aws_eip.ec2_vpn_instance.public_ip
    VPC_CIDR               = module.vpc.vpc_cidr_block
    WG_IS_SEND_CLIENT_CONF = var.wg_admin_email != null ? true : false
    WG_ADMIN_EMAIL         = var.wg_admin_email
    WG_SEND_LAMBDA_NAME    = "${local.name}-send-wg-conf"
  }
  allowed_triggers = {
    AllowExecutionFromSNS = {
      principal  = "sns.amazonaws.com"
      source_arn = aws_sns_topic.wireguard_group_change_notification.arn
    }
  }
}

module "wg_manage_image" {
  source          = "terraform-aws-modules/lambda/aws//modules/docker-build"
  create_ecr_repo = true
  ecr_repo        = "${local.name}-wg-manage"
  image_tag       = filesha256("../../lambdas/wg-manage/app.py")
  source_path     = "${path.module}/lambdas/wg-manage"
}

