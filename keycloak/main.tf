data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_region" "current" {}

resource "kubernetes_namespace" "this" {
  depends_on = [
    var.module_depends_on
  ]
  count = var.namespace == "" ? 1 - local.argocd_enabled : 0
  metadata {
    name = var.namespace_name
  }
}

resource "helm_release" "keycloak" {
  count = 1 - local.argocd_enabled
  depends_on = [
    var.module_depends_on
  ]
  repository    = local.repository
  name          = local.name
  chart         = local.chart
  version       = local.version
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
  count      = local.argocd_enabled
  depends_on = [
    var.module_depends_on
  ]
  content    = yamlencode(local.application)
  filename   = "${path.root}/${var.argocd.path}/${local.name}.yaml"
}

locals {
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
  namespace      = coalescelist(kubernetes_namespace.this, [{ "metadata" = [{ "name" = var.namespace }] }])[0].metadata[0].name

  repository    = "https://charts.bitnami.com/bitnami"
  name          = "keycloak"
  chart         = "keycloak"
  version       = var.chart_version
  conf          = merge(local.conf_defaults, var.conf)
  conf_defaults = {
    "rbac.create"               = true,
    "resources.limits.cpu"      = "512m",
    "resources.limits.memory"   = "2048Mi",
    "resources.requests.cpu"    = "512m",
    "resources.requests.memory" = "512Mi",
    "aws.region"                = data.aws_region.current.name
  }

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
}

