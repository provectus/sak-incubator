data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

resource "kubernetes_namespace" "this" {
  depends_on = [
    var.module_depends_on
  ]
  count = var.namespace == "" ? 1 : 0
  metadata {
    name = var.namespace_name
  }
}

resource "aws_s3_bucket" "registry" {
  count         = 1 - local.storage
  bucket        = "registry-mirror-bucket"
  acl           = "private"
  force_destroy = true

  tags = var.tags
}

resource "aws_iam_user" "registry" {
  count = 1 - local.storage
  name  = "${var.cluster_name}-registry"
  path  = "/system/"

  tags = var.tags
}

resource "aws_iam_access_key" "registry" {
  count = 1 - local.storage
  user  = aws_iam_user.registry.name
}

resource "aws_iam_user_policy" "registry" {
  count = 1 - local.storage
  name  = "${var.cluster_name}-registry"
  user  = aws_iam_user.registry.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.registry.arn}
    }
  ]
}
EOF
}

resource "helm_release" "this" {
  count = 1 - local.argocd_enabled
  depends_on = [
    var.module_depends_on
  ]
  name       = local.name
  repository = local.repository
  chart      = local.chart
  version    = local.version
  namespace  = local.namespace
  timeout    = 1200

  dynamic "set" {
    for_each = local.conf

    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "local_file" "this" {
  count    = local.argocd_enabled
  content  = yamlencode(local.app)
  filename = "${var.argocd.path}/${local.name}.yaml"
}

locals {
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
  s3_enabled     = var.storage == "s3" ? 0 : 1
  namespace      = coalescelist(kubernetes_namespace.this, [{ "metadata" = [{ "name" = var.namespace }] }])[0].metadata[0].name

  name       = "proxy"
  repository = "https://helm.twun.io"
  chart      = "docker-registry"
  version    = var.chart_version


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
    var.storage == "filesystem" ? {
      "persistence.enabled" = true
      "persistence.size"    = "10Gi"
    } : {},
    var.storage == "s3" ? {
      "persistence.enabled"  = false
      "s3.region"            = aws_s3_bucket.registry.region
      "s3.bucket"            = aws_s3_bucket.registry.id
      "s3.secure"            = true
      "secrets.s3.accessKey" = aws_iam_access_key.registry.id
      "secrets.s3.secretKey" = aws_iam_access_key.registry.secret
    } : {},
    {
      "ingress.enabled"                                      = true
      "ingress.hosts[0]"                                     = "docker-hub-mirror.${var.domains[0]}"
      "ingress.tls[0].secretName"                            = "docker-hub-mirror-tls"
      "ingress.tls[0].hosts[0]"                              = "docker-hub-mirror.${var.domains[0]}"
      "ingress.annotations.cert-manager\\.io/cluster-issuer" = "letsencrypt-prod"
      "ingress.annotations.kubernetes\\.io/tls-acme"         = "true"
      "ingress.annotations.kubernetes\\.io/ingress\\.class"  = "internal"
      "configData.proxy.remoteurl"                           = "https://registry-1.docker.io"
  })
}
