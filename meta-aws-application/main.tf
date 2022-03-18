data "aws_eks_cluster" "this" {
  count = local.use_aws ? 1 : 0
  name  = var.cluster_name
}

resource "kubernetes_namespace" "this" {
  count = var.namespace == "default" ? 1 - local.argocd_enabled : 0
  metadata {
    name = var.namespace_name
  }
}

resource "helm_release" "app" {
  count      = 1 - local.argocd_enabled
  name       = local.name
  repository = var.repository
  chart      = var.chart
  version    = var.chart_version
  namespace  = local.namespace
  timeout    = 1200
  values     = [var.values]
  set {
    name  = var.irsa_annotation_field
    value = local.aws_role_arn
  }
}

module "iam_assumable_role" {
  count        = local.use_aws ? 1 : 0
  source       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version      = "~> v4.3.0"
  role_name    = "${var.cluster_name}_${local.name}"
  create_role  = var.iam_permissions == [] ? false : true
  provider_url = replace(data.aws_eks_cluster.this[0].identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns = [for p in aws_iam_policy.app :
    p.arn
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.namespace}:${var.service_account_name == "" ? local.name : var.service_account_name}"]
  tags                          = var.tags
}

resource "aws_iam_policy" "app" {
  count = local.use_aws ? 1 : 0
  name  = "${var.cluster_name}_${local.name}"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = var.iam_permissions
  })
  tags = var.tags
}

resource "local_file" "app" {
  count    = local.argocd_enabled
  content  = data.utils_deep_merge_yaml.merged.output
  filename = "${var.argocd.path}/${local.name}.yaml"
}

data "utils_deep_merge_yaml" "merged" {
  input = [
    yamlencode(local.app),
    yamlencode(var.argocd_custom_app_settings)
  ]
  deep_copy_list = true
}

locals {
  name           = var.name == "" ? var.chart : var.name
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
  use_aws        = var.iam_permissions == [] ? false : true
  aws_role_arn   = coalescelist(module.iam_assumable_role, [{ iam_role_arn = "" }])[0].iam_role_arn
  namespace      = coalescelist(kubernetes_namespace.this, [{ "metadata" = [{ "name" = var.namespace }] }])[0].metadata[0].name
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
        "server"    = var.destination_server
      }
      "project" = var.project == "" ? var.argocd.project : var.project
      "source" = {
        "repoURL"        = var.repository
        "targetRevision" = var.chart_version
        "chart"          = var.chart
        "helm" = merge(
          local.aws_role_arn == "" ? {} : {
            "parameters" = [
              {
                "name"  = var.irsa_annotation_field
                "value" = local.aws_role_arn
              }
            ]
          },
          {
            "values" = var.values
          }
        )
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
