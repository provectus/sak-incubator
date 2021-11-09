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

resource "kubernetes_persistent_volume_claim" "this" {
  metadata {
    name      = var.pvc_name
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.this.metadata.0.name
    resources {
      requests = {
        storage = var.pvc_size
      }
    }
  }
}

resource "kubernetes_storage_class" "this" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Retain"
  mount_options       = var.mount_options
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = "${aws_efs_file_system.this.id}"
    directoryPerms   = var.efs_permissions
  }
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


resource "helm_release" "aws_efs_csi_driver" {
  count      = 1 - local.argocd_enabled
  name       = local.name
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = local.chart
  namespace  = "kube-system"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.this.arn
  }
}

locals {
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
  namespace      = var.namespace

  name       = var.chart_name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = var.chart_name
  version    = var.chart_version

  efs_app = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = local.name
      "namespace" = local.argocd_enabled == 1 ? var.argocd.namespace : "default"
    }
    "spec" = {
      "destination" = {
        "namespace" = local.namespace
        "server"    = "https://kubernetes.default.svc"
      }
      "project" = "default"
      "source" = {
        "repoURL"        = local.repository
        "targetRevision" = local.version
        "chart"          = local.chart
        "helm" = {
          "parameters" = values({
            for key, value in local.conf :
            key => {
              "name"  = key
              "value" = tostring(value)
            }
          })
        }
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
      }
    }
  }
  conf = merge(local.conf_defaults, var.conf)
  conf_defaults = merge(
    {
      "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" : aws_iam_role.this.arn
  })

  sc_manifest = <<YAML
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
parameters:
  directoryPerms: ${var.efs_permissions}
  fileSystemId: ${aws_efs_file_system.this.id}
  provisioningMode: efs-ap
provisioner: efs.csi.aws.com
reclaimPolicy: Retain
volumeBindingMode: Immediate
YAML

  pvc_manifest = <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${var.pvc_name}
  namespace: ${var.namespace}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ${kubernetes_storage_class.this.metadata.0.name}
  resources:
    requests:
      storage: ${var.pvc_size}
YAML
}


resource "local_file" "storageclass" {
  count    = local.argocd_enabled
  content  = yamlencode(local.sc_manifest)
  filename = "${var.argocd.path}/storageclass.yaml"
}

resource "local_file" "pvc" {
  count    = local.argocd_enabled
  content  = yamlencode(local.pvc_manifest)
  filename = "${var.argocd.path}/pvc.yaml"
}

resource "local_file" "this" {
  count    = local.argocd_enabled
  content  = yamlencode(local.efs_app)
  filename = "${var.argocd.path}/${local.name}.yaml"
}
