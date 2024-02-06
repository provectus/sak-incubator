data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_region" "current" {}

resource "random_password" "keycloak_password" {
  depends_on = [
    var.module_depends_on
  ]
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "keycloak_password" {
  name  = "/${var.cluster_name}/keycloak/password"
  type  = "SecureString"
  value = local.password
}

resource "kubernetes_namespace" "this" {
  depends_on = [
    var.module_depends_on
  ]
  count = var.namespace == "" ? 1 - local.argocd_enabled : 0
  metadata {
    name = var.namespace_name
  }
}

resource "kubernetes_secret" "keycloak_auth" {
  depends_on = [
    var.module_depends_on
  ]

  count = var.keycloak_google_auth ? 1 - local.argocd_enabled : 0

  metadata {
    name      = "keycloak-auth"
    namespace = local.namespace
  }

  data = {
    KC_AUTH_GOOGLE_CLIENT_ID     = var.keycloak_client_id
    KC_AUTH_GOOGLE_CLIENT_SECRET = var.keycloak_client_secret
  }
}

resource "aws_kms_ciphertext" "keycloak_client_secret" {
  count     = var.keycloak_google_auth && local.argocd_enabled > 0 ? 1 : 0
  key_id    = var.argocd.kms_key_id
  plaintext = base64encode(var.keycloak_client_secret)
}

resource "aws_kms_ciphertext" "keycloak_password" {
  count     = local.argocd_enabled
  key_id    = var.argocd.kms_key_id
  plaintext = local.password
}

resource "local_file" "namespace" {
  count = local.argocd_enabled
  depends_on = [
    var.module_depends_on
  ]
  content = yamlencode({
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "name" = local.namespace
    }
  })
  filename = "${path.root}/${var.argocd.path}/ns-${local.namespace}.yaml"
}

resource "local_file" "keycloak_auth" {
  count = var.keycloak_google_auth ? local.argocd_enabled : 0
  depends_on = [
    var.module_depends_on
  ]
  content = yamlencode({
    "apiVersion" = "v1"
    "kind"       = "Secret"
    "metadata" = {
      "name"      = "keycloak-auth"
      "namespace" = local.namespace
    }
    "stringData" = {
      "KC_AUTH_GOOGLE_CLIENT_ID"     = var.keycloak_client_id
      "KC_AUTH_GOOGLE_CLIENT_SECRET" = "KMS_ENC:${aws_kms_ciphertext.keycloak_client_secret[0].ciphertext_blob}:"
    }
  })
  filename = "${path.root}/${var.argocd.path}/secret-keycloak-auth.yaml"
}

locals {
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
  namespace      = coalescelist(var.namespace == "" && local.argocd_enabled > 0 ? [{ "metadata" = [{ "name" = var.namespace_name }] }] : kubernetes_namespace.this, [{ "metadata" = [{ "name" = var.namespace }] }])[0].metadata[0].name
}

resource "helm_release" "this" {
  count = 1 - local.argocd_enabled

  depends_on = [
    var.module_depends_on
  ]

  name          = local.name
  repository    = local.repository
  chart         = local.chart
  version       = var.chart_version
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
  name       = "kube-keycloak"
  repository = "https://github.com/bitnami/charts/tree/master/bitnami/keycloak/"
  chart      = "kube-keycloak"
  conf       = merge(local.conf_defaults, var.conf)
  password   = var.keycloak_password == "" ? random_password.keycloak_password.result : var.keycloak_password
  conf_defaults = {
    "keycloak.enabled"                                 = true
    "keycloak.pvc.enabled"                             = true
    "keycloak.ingress.enabled"                         = true
    "keycloak.ingress.hosts[0]"                        = "keycloak.${var.domains[0]}"
    "keycloak.adminPassword"                           = local.argocd_enabled > 0 ? "KMS_ENC:${aws_kms_ciphertext.keycloak_password[0].ciphertext_blob}:" : local.password
    "keycloak.env.KC_AUTH_GOOGLE_ENABLED"              = var.keycloak_google_auth
    "keycloak.env.KC_AUTH_GOOGLE_ALLOWED_DOMAINS"      = var.keycloak_allowed_domains
    "keycloak.env.KC_AUTH_GOOGLE_CLIENT_ID"            = var.keycloak_client_id
    //TODO: Change to work with secret
    "keycloak.env.KC_AUTH_GOOGLE_CLIENT_SECRET"        = var.keycloak_client_secret
    "keycloak.ingress.enabled"                      = false
    "namespace"                                       = local.namespace
    "rbac.create"                                     = true,
    "resources.limits.cpu"                            = "100m",
    "resources.limits.memory"                         = "300Mi",
    "resources.requests.cpu"                          = "100m",
    "resources.requests.memory"                       = "300Mi"
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
        "targetRevision" = var.chart_version
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