data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_vpc" "this" {
  id = data.aws_eks_cluster.cluster.vpc_config.0.vpc_id
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"] # eks nodes running in private subnets
  }
}

provider "aws" {
  alias  = "sak-efs"
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "aws_kms_key" "this" {
  description = "EFS folder Encryption Key"
}

resource "aws_efs_file_system" "this" {
  creation_token = var.efs_name

  encrypted  = true
  kms_key_id = aws_kms_key.this.arn
  tags       = var.tags
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id
  root_directory {
    creation_info {
      owner_gid   = var.efs_owner_gid
      owner_uid   = var.efs_owner_uid
      permissions = var.efs_folder_permissions
    }
    path = var.efs_folder_path
  }
  tags = var.tags
}

resource "aws_efs_mount_target" "this" {
  for_each        = { for subnet in data.aws_subnets.this.ids : subnet => subnet }
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.key
  security_groups = [aws_security_group.this.id]
}


resource "aws_security_group_rule" "this" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  description       = "Allows EFS traffic"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group" "this" {
  name   = "allow-efs"
  vpc_id = data.aws_vpc.this.id
}

resource "helm_release" "aws_efs_csi_driver" {
  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  namespace  = "kube-system"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.this.arn
  }
}

resource "kubernetes_persistent_volume" "this" {
  depends_on = [helm_release.aws_efs_csi_driver]
  metadata {
    name = var.pv_name
  }
  spec {
    capacity = {
      storage = var.pv_size
    }
    access_modes = ["ReadWriteMany"]

    storage_class_name = kubernetes_storage_class.this.metadata.0.name
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = "${aws_efs_file_system.this.id}::${aws_efs_access_point.this.id}"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "this" {
  depends_on = [kubernetes_persistent_volume.this]
  metadata {
    name      = var.pvc_name
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.pvc_size
      }
    }
    storage_class_name = kubernetes_storage_class.this.metadata.0.name
    volume_name        = kubernetes_persistent_volume.this.metadata.0.name
  }
}

resource "kubernetes_storage_class" "this" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Retain"
  mount_options       = ["file_mode=0700", "dir_mode=0777", "mfsymlinks", "uid=1000", "gid=1000", "nobrl", "cache=none"]
}

resource "aws_iam_role_policy" "this" {
  name = "EFSAllowDescribe"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticfilesystem:Describe*",
        ]
        Effect   = "Allow"
        Resource = aws_efs_file_system.this.arn
      },
    ]
  })
}

resource "aws_iam_role" "this" {
  name = "${var.cluster_name}-efs-csi-driver"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
