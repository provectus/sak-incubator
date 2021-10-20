data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

locals {
  vault_conf = <<EOT
ui = true
listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
}
EOT

  file_storage_conf = {
    "server.volumes[0].name"                            = var.file_storage_name,
    "server.volumes[0].persistentVolumeClaim.claimName" = var.file_storage_pvc_name,
    "server.standalone.config"                          = <<EOT
    ${local.vault_conf}
    storage "file" {
      path = "/vault/data"
    }
EOT
  }

  init_conf = {
    "server.ui.enabled" = true
  }
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

resource "kubernetes_namespace" "this" {
  count = var.chart_create_namespace ? 1 : 0
  metadata {
    annotations = {
      name = var.chart_namespace
    }

    name = var.chart_namespace
  }
}

resource "aws_kms_key" "this" {
  count                   = var.s3_create_bucket ? 1 : 0
  description             = "Key for vault s3 bucket"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "this" {
  count  = var.s3_create_bucket ? 1 : 0
  bucket = var.s3_bucket_name
  acl    = "private"

  tags = var.tags
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.this.0.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_iam_user_policy" "this" {
  count = var.s3_storage ? 1 : 0
  name  = "VaultUserPermissions"
  user  = aws_iam_user.this.0.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      },
    ]
  })
}

resource "aws_iam_user" "this" {
  count = var.s3_storage ? 1 : 0
  name  = "${var.cluster_name}-vault"
  path  = "/vault/"

  tags = var.tags
}

resource "aws_iam_access_key" "this" {
  count = var.s3_storage ? 1 : 0
  user  = aws_iam_user.this.0.name
}


resource "helm_release" "this" {
  depends_on = [kubernetes_namespace.this]
  name       = var.chart_name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = var.chart_namespace

  dynamic "set" {
    for_each = local.init_conf

    content {
      name  = set.key
      value = set.value
    }
  }
  dynamic "set" {
    for_each = var.s3_storage ? [local.init_conf] : []
    content {
      name  = "server.standalone.config"
      value = <<EOT
${local.vault_conf}
storage "s3" {
  access_key = "${aws_iam_access_key.this.0.id}"
  secret_key = "${aws_iam_access_key.this.0.secret}"
  bucket     = "${var.s3_bucket_name}"
  region     = "${var.s3_bucket_region}"
}
EOT
    }
  }

  dynamic "set" {
    for_each = var.file_storage ? local.file_storage_conf : {}
    content {
      name  = set.key
      value = set.value
    }
  }
}
