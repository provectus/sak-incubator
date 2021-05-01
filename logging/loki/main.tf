data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

# creating grafana password
resource "random_password" "grafana_loki_password" {
  depends_on = [
    var.module_depends_on
  ]
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "grafana_loki_password" {
  name  = "/${var.cluster_name}/grafana-loki/password"
  type  = "SecureString"
  value = local.password
}

resource "aws_kms_ciphertext" "grafana_loki_password" {
  count     = local.argocd_enabled
  key_id    = var.argocd.kms_key_id
  plaintext = local.password
}

# Create namespace logging
resource "kubernetes_namespace" "this" {
  depends_on = [
    var.module_depends_on
  ]
  count = var.namespace == "" ? 1 - local.argocd_enabled : 0
  metadata {
    name = var.namespace_name
  }
}

resource "helm_release" "this" {
  count = 1 - local.argocd_enabled

  depends_on = [
    var.module_depends_on
  ]

  name          = local.name
  repository    = local.repository
  chart         = local.chart
  version       = local.version
  namespace     = local.namespace
  recreate_pods = true
  timeout       = 1200

  dynamic "set" {
    for_each = merge(local.conf)

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
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
  namespace      = coalescelist(var.namespace == "" && local.argocd_enabled > 0 ? [{ "metadata" = [{ "name" = var.namespace_name }] }] : kubernetes_namespace.this, [{ "metadata" = [{ "name" = var.namespace }] }])[0].metadata[0].name

  name       = "loki-stack"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = var.chart_version
  conf       = merge(local.conf_defaults, var.conf)
  password   = var.grafana_loki_password == "" ? random_password.grafana_loki_password.result : var.grafana_loki_password

  conf_defaults = {
    "loki.enabled"                        = true
    "promtail.enabled"                    = true
    "fluent-bit.enabled"                  = false
    "grafana.enabled"                     = true
    "grafana.pvc.enabled"                 = true
    "grafana.adminPassword"               = "KMS_ENC:${aws_kms_ciphertext.grafana_loki_password[0].ciphertext_blob}:"
    "grafana.sidecar.datasources.enabled" = true
    "grafana.image.tag"                   = "6.7.0"
    "prometheus.enabled"                  = false
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
        "syncOptions" = [
          "CreateNamespace=true"
        ]
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
      }
    }
  }
}
