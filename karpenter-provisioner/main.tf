
locals {
  provisioner_app = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = var.application_name
      "namespace" = var.argocd.namespace
    }
    "spec" = {
      "project" = var.argocd.project
      "source" = {
        "repoURL"        = var.argocd.repository
        "targetRevision" = var.argocd.branch
        "path"           = "${var.argocd.full_path}/${var.application_name}"
      }
      "destination" = {
        "server" = "https://kubernetes.default.svc"
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
resource "local_file" "provisioner_app" {
  count    = var.argocd_enabled ? 1 : 0
  content  = yamlencode(local.provisioner_app)
  filename = "${path.root}/${var.argocd.path}/${var.application_name}.yaml"
}

module "provisioners" {
  source   = "./modules/provisioners"
  for_each = { for k, v in var.provisioners : k => v }

  application_name = var.application_name
  apps_dir         = var.argocd.path
  argocd_enabled   = var.argocd_enabled

  name                                  = try(each.value.name, each.key)
  requirements                          = try(each.value.requirements, [])
  taints                                = try(each.value.taints, [])
  startup_taints                        = try(each.value.startup_taints, [])
  labels                                = try(each.value.labels, {})
  annotations                           = try(each.value.annotations, {})
  container_runtime                     = try(each.value.container_runtime, "containerd")
  cluster_dns                           = try(each.value.cluster_dns, [])
  kubelet_system_reserved               = try(each.value.kubelet_system_reserved, {})
  kubelet_kube_reserved                 = try(each.value.kubelet_kube_reserved, {})
  kubelet_eviction_hard                 = try(each.value.kubelet_eviction_hard, {})
  kubelet_eviction_soft                 = try(each.value.kubelet_eviction_soft, {})
  kubelet_eviction_soft_grace_period    = try(each.value.kubelet_eviction_soft_grace_period, {})
  kubelet_eviction_max_pod_grace_period = try(each.value.kubelet_eviction_max_pod_grace_period, null)
  kubelet_pods_per_core                 = try(each.value.kubelet_pods_per_core, null)
  kubelet_max_pods                      = try(each.value.kubelet_max_pods, null)
  resources_limits                      = try(each.value.resources_limits, {})
  consolidation_enabled                 = try(each.value.consolidation_enabled, true)
  ttl_secondes_after_empty              = try(each.value.ttl_secondes_after_empty, null)
  ttl_seconds_untill_expierd            = try(each.value.ttl_seconds_untill_expierd, null)
  weight                                = try(each.value.weight, null)
  ami_family                            = try(each.value.ami_family, "AL2")
  block_device_mappings                 = try(each.value.block_device_mappings, [])
  metadata_options                      = try(each.value.metadata_options, {})
  instace_profile                       = try(each.value.instace_profile, null)
  detailed_monitoring_enabled           = try(each.value.detailed_monitoring_enabled, false)
  tags                                  = try(merge(each.value.tags, { "karpenter.sh/discovery" = "${var.cluster_name}" }), { "karpenter.sh/discovery" = "${var.cluster_name}" })
  subnet_selector                       = try(each.value.subnet_selector, { "karpenter.sh/discovery" = "true" })
  sg_selector                           = try(each.value.sg_selector, { "karpenter.sh/discovery" = "${var.cluster_name}" })
  ami_selector                          = try(each.value.ami_selector, {})
  user_data                             = try(each.value.user_data, null)
}