data "aws_eks_cluster" "this" {
  name = var.cluster_name
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
  values     = [yamlencode(var.values)]
  set {
    name  = var.irsa_annotation_field
    value = module.iam_assumable_role.iam_role_arn
  }
}

module "iam_assumable_role" {
  source       = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version      = "~> v4.3.0"
  role_name    = "${var.cluster_name}_${local.name}"
  create_role  = var.iam_permissions == [] ? false : true
  provider_url = replace(data.aws_eks_cluster.this.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns = [for p in aws_iam_policy.app :
    p.arn
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.namespace}:${var.service_account_name == "" ? local.name : var.service_account_name}"]
  tags                          = var.tags
}

resource "aws_iam_policy" "app" {
  count = var.iam_permissions == [] ? 0 : 1
  name  = "${var.cluster_name}_${local.name}"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = var.iam_permissions
  })
  tags = var.tags
}

resource "local_file" "app" {
  count    = local.argocd_enabled
  content  = yamlencode(local.app)
  filename = "${var.argocd.path}/${local.name}.yaml"
}

locals {
  name           = var.name == "" ? var.chart : var.name
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
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
      "project" = var.argocd.project
      "source" = {
        "repoURL"        = var.repository
        "targetRevision" = var.chart_version
        "chart"          = var.chart
        "helm" = {
          "parameters" = [
            {
              "name"  = var.irsa_annotation_field
              "value" = module.iam_assumable_role.iam_role_arn
            }
          ]
          "values" = yamlencode(var.values)
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
