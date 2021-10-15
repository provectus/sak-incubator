resource "aws_iam_instance_profile" "ec2_vpn_server" {
  name_prefix = local.name
  role        = aws_iam_role.ec2_vpn_server.name
}

data "aws_iam_policy_document" "ec2_vpn_server" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_vpn_server" {
  name_prefix           = "${local.name}-"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.ec2_vpn_server.json
}

resource "aws_iam_policy" "ec2_vpn_server_ssm" {
  policy = <<POLICY
{
"Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
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

resource "aws_iam_role_policy_attachment" "ec2_vpn_server_ssm" {
  policy_arn = aws_iam_policy.ec2_vpn_server_ssm.arn
  role       = aws_iam_role.ec2_vpn_server.name
}


data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/hvm-ssd/ubuntu-focal-20.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ec2_vpn_server" {
  name        = "${local.name}-ec2_vpn_server"
  description = "allow external access"
  vpc_id      = local.wg_vpc_id
  ingress     = [
    {
      description      = "VPN traffic"
      from_port        = var.listen-port
      to_port          = var.listen-port
      protocol         = "udp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      self             = true
      prefix_list_ids  = null
      security_groups  = null
    }
  ]
  egress      = [
    {
      description      = "Allow all outgoing traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      security_groups  = null
      self             = false
    }
  ]
}

resource "aws_security_group" "ec2_vpn_server_ssh" {
  name        = "${local.name}-ec2-vpn-server-ssh"
  description = "allow external access"
  vpc_id      = local.wg_vpc_id
  count       = var.aws_ec2_key != null ? 1 : 0
  ingress     = [
    {
      description      = "ssh if needed"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      self             = true
      prefix_list_ids  = null
      security_groups  = null
    }
  ]
}

resource "aws_eip" "ec2_vpn_instance" {
  vpc  = true
  tags = merge({
    Name = "${local.name}-wireguard"
  })
  lifecycle {
    ignore_changes = [tags]
  }
}

module "ec2_vpn_instance" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 3.0"
  iam_instance_profile        = aws_iam_instance_profile.ec2_vpn_server.name
  associate_public_ip_address = true
  name                        = "${local.name}-vpn-server"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.aws_ec2_key
  monitoring                  = false
  vpc_security_group_ids      = (var.aws_ec2_key == null
  ?  [aws_security_group.ec2_vpn_server.id]
  : [ aws_security_group.ec2_vpn_server.id, aws_security_group.ec2_vpn_server_ssh[0].id ])
  subnet_id                   = local.wg_subnet
  hibernation                 = false
  cpu_credits                 = "unlimited"

  user_data = <<-EOT
#!/usr/bin/env bash
apt-get update
apt-get install -y awscli jq wireguard iptables
sleep 5
REGION=`curl http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}'`
aws --region=$REGION ssm get-parameter --with-decryption --name "${local.wg_ssm_config}" | jq -r .Parameter.Value > /etc/wireguard/wg0.conf
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p
sleep 20
systemctl start wg-quick@wg0.service
systemctl status wg-quick@wg0.service
rm /var/lib/cloud/instances/*/sem/config_scripts_user || true
EOT
}

resource "aws_eip_association" "vpn_server_eip" {
  instance_id   = module.ec2_vpn_instance.id
  allocation_id = aws_eip.ec2_vpn_instance.id
}

resource "aws_ssm_parameter" "wg-instance-id" {
  name        = local.wg_ssm_instance_id
  description = "Wireguard server instance id"
  type        = "String"
  value       = module.ec2_vpn_instance.id
}

output "vpn_external_address" {
  value = aws_eip.ec2_vpn_instance.address
}