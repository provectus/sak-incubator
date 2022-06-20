data "aws_region" "current" {}

data "kubernetes_namespace" "ebs_csi_driver" {
  metadata {
    name = "kube-system"
  }
}

data "aws_caller_identity" "current" {}


# Create role for ebs-csi-driver
resource "aws_iam_policy" "ebs_csi_driver" {
  name = "${var.cluster_name}-ebs-csi-driver"

  policy                  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": [
            "CreateVolume",
            "CreateSnapshot"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteTags"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
EOF
}

# Create role for ebs-driver
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.cluster_name}_ebs-csi-driver"
  description        = "Role for ebs-csi-driver"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(var.cluster_oidc_url, "https://", "")}:sub": "system:serviceaccount:${data.kubernetes_namespace.ebs_csi_driver.metadata[0].name}:aws-ebs-csi-driver"
        }
      },
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.cluster_oidc_url, "https://", "")}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Attach policy ebs-driver to role ebs-driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  depends_on = [
    aws_iam_policy.ebs_csi_driver
  ]
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = aws_iam_policy.ebs_csi_driver.arn
}

resource "helm_release" "ebs_driver" {
  depends_on = [
    aws_iam_role.ebs_csi_driver
  ]
  name       = "ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  version    = "2.6.2"
  namespace  = data.kubernetes_namespace.ebs_csi_driver.metadata[0].name
  #namespace = "kube-system"


  values = [templatefile("${path.module}/values/values.yaml",
    {
      cluster_name = var.cluster_name
      vpc_id       = var.vpc_id
      region       = data.aws_region.current.name
      role-arn     = aws_iam_role.ebs_csi_driver.arn
    })
  ]
}