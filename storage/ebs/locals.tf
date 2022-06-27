locals {
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
  namespace      = coalescelist(kubernetes_namespace.this, [{ "metadata" = [{ "name" = var.namespace }] }])[0].metadata[0].name
}

locals {
  repository    = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  name          = "aws-ebs-csi-driver"
  chart         = "aws-ebs-csi-driver"
  chart_version = var.chart_version
  conf          = merge(local.conf_defaults, var.conf)
  conf_defaults = {
    "storageClasses[0].name"                                                        = "ebs-sc",
    "storageClasses[0].annotations.storageclass\\.kubernetes\\.io/is-default-class" = "\"true\"",
    "storageClasses[0].volumeBindingMode"                                           = "WaitForFirstConsumer"
    "storageClasses[0].reclaimPolicy"                                               = "Retain"
    "storageClasses[0].allowVolumeExpansion"                                        = true,
    "storageClasses[0].parameters.encrypted"                                        = "\"true\"",
    "resources.limits.cpu"                                                          = "100m",
    "resources.limits.memory"                                                       = "128Mi",
    "resources.requests.cpu"                                                        = "50m",
    "resources.requests.memory"                                                     = "64Mi",
    "controller.region"                                                             = data.aws_region.current.name
    "controller.serviceAccount.create"                                              = false,
    "controller.serviceAccount.name"                                                = local.name,
    "controller.logLevel"                                                           = "3",
    "controller.extraVolumeTags.PartOf" : "k8s",
    "controller.extraVolumeTags.cluster_name" : data.aws_eks_cluster.this.name,


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
        "targetRevision" = local.chart_version
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