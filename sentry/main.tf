data "aws_region" "current" {}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

resource "kubernetes_namespace" "this" {
  count = var.namespace == "" ? 1 : 0
  metadata {
    name = var.namespace_name
  }
}

resource "random_password" "this" {
  length           = 16
  special          = true
  override_special = "_%@$"
}

resource "aws_ssm_parameter" "this" {
  name        = "/${var.cluster_name}/sentry/password"
  type        = "SecureString"
  value       = random_password.this.result
  description = "A password for accessing Sentry in ${var.cluster_name} EKS cluster"
  lifecycle {
    ignore_changes = [value]
  }
  tags = var.tags
}

locals {
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
  namespace      = coalescelist(kubernetes_namespace.this, [{ "metadata" = [{ "name" = var.namespace }] }])[0].metadata[0].name
}

resource "helm_release" "this" {
  count = 1 - local.argocd_enabled
  depends_on = [
    var.module_depends_on
  ]
  name          = local.name
  repository    = local.repository
  chart         = local.chart
  version       = local.chart_version
  namespace     = local.namespace
  recreate_pods = true
  timeout       = 1200

  dynamic "set" {
    for_each = local.conf

    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "local_file" "this" {
  count = local.argocd_enabled
  depends_on = [
    var.module_depends_on
  ]
  content  = yamlencode(local.application)
  filename = "${path.root}/${var.argocd.path}/${local.name}.yaml"
}

locals {
  repository    = "https://sentry-kubernetes.github.io/charts"
  name          = "sentry"
  chart         = "sentry"
  chart_version = var.chart_version
  conf          = merge(local.conf_defaults, var.conf)
  conf_defaults = merge({
    "user.create" = true,
    "user.email" = "admin@sentry.local",
    "user.password" = "${random_password.this.result}",
    "sentry.singleOrganization" = true,
    "sentry.worker.replicas"    = 2,
    "ingress.enabled"           = true,
    "ingress.regexPathStyle"    = "nginx",
    "ingress.hostname"          = "sentry.${var.domain}",
    "service.name"              = "sentry",
    "service.type"              = "ClusterIP",
    "service.externalPort"      = 9000,
    "service.annotations"       = "{}"
    }
  )
  application = {
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
        "targetRevision" = local.chart_version
        "chart"          = local.chart
        "helm" = {
          "parameters" = concat(
            values({
              for key, value in local.conf :
              key => {
                "name"  = key
                "value" = tostring(value)
              }
            }),
            values({
              for key, value in var.ingress_annotations :
              key => {
                "name"        = "ingress.annotations.${replace(key, ".", "\\.")}"
                "value"       = tostring(value)
                "forceString" = true
              }
            })
          )
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
}
