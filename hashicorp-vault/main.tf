data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
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
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "s3:*"
        ],
        "Resource" = "${aws_s3_bucket.this.0.arn}/*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "this" {
  count      = var.s3_storage ? 1 : 0
  name       = "vault-${var.cluster_name}"
  users      = [aws_iam_user.this.0.name]
  roles      = []
  groups     = []
  policy_arn = aws_iam_policy.this.0.arn
}


resource "aws_iam_policy" "this" {
  count       = var.s3_storage ? 1 : 0
  name_prefix = "vault-kms"
  description = "EKS VAULT policy for cluster"
  policy      = data.aws_iam_policy_document.this.0.json
}

data "aws_iam_policy_document" "this" {
  count = var.s3_storage ? 1 : 0
  statement {
    sid    = "VaultOwn"
    effect = "Allow"

    actions = [
      "kms:*"
    ]

    resources = [aws_kms_key.this.0.arn]
  }
}

# TODO test usage of iam role and try to read credentials from secret
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

resource "local_file" "this" {
  count    = local.argocd_enabled
  content  = yamlencode(local.app)
  filename = "${var.argocd.path}/${local.name}.yaml"
}


resource "helm_release" "this" {
  count      = 1 - local.argocd_enabled
  depends_on = [kubernetes_namespace.this]
  name       = local.name
  repository = local.repository
  chart      = local.chart
  namespace  = local.namespace

  dynamic "set" {
    for_each = local.conf

    content {
      name  = set.key
      value = set.value
    }
  }
}

locals {
  name           = var.chart_name
  repository     = "https://helm.releases.hashicorp.com"
  chart          = "vault"
  version        = var.chart_version
  namespace      = var.chart_namespace
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0

  app = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = local.name
      "namespace" = var.argocd.namespace
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
    var.s3_storage ? {
      "server.standalone.config" = <<EOT
${local.vault_conf}
storage "s3" {
  access_key = "${aws_iam_access_key.this.0.id}"
  secret_key = "${aws_iam_access_key.this.0.secret}"
  bucket     = "${var.s3_bucket_name}"
  region     = "${var.s3_bucket_region}"
}
EOT
    } : {},
    var.file_storage ? {
      "server.volumes[0].name"                            = var.file_storage_name,
      "server.volumes[0].persistentVolumeClaim.claimName" = var.file_storage_pvc_name,
      "server.standalone.config"                          = <<EOT
${local.vault_conf}
storage "file" {
  path = "/vault/data"
}
EOT
    } : {},
    {
  })

  vault_conf = <<EOT
listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
}
EOT
}
