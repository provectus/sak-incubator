locals {
  user_data_al2_ubuntu = <<EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

--BOUNDARY
Content-Type: text/x-shellscript; charset="us-ascii"
${var.user_data == null ? "" : var.user_data}
--BOUNDARY--
EOF
}

locals {
  provisioner = {
    "apiVersion" = "karpenter.sh/v1alpha5"
    "kind"       = "Provisioner"
    "metadata" = {
      "name" = var.name
    }
    "spec" = merge({
      "providerRef" = {
        "name" = var.name
      }
      },
      local.requirements,
      local.labels,
      local.taints,
      local.annotations,
      local.startup_taints,
      local.kubelet_configuration,
      local.resources_limits,
      local.consolidation_enabled,
      local.ttl_secondes_after_empty,
      local.ttl_seconds_untill_expierd,
      local.weight

    )
  }
  node_template = {
    "apiVersion" = "karpenter.k8s.aws/v1alpha1"
    "kind"       = "AWSNodeTemplate"
    "metadata" = {
      "name" = var.name
    }
    "spec" = merge({
      "subnetSelector"        = var.subnet_selector
      "securityGroupSelector" = var.sg_selector
      "amiFamily"             = var.ami_family
      "metadataOptions"       = var.metadata_options
      "detailedMonitoring"    = var.detailed_monitoring_enabled
      },
      local.instace_profile,
      local.tags,
      local.ami_selector,
      local.block_device_mappings,
      local.user_data
    )
  }
  default_requirements = [
    {
      "key"      = "kubernetes.io/os"
      "operator" = "In"
      "values"   = ["linux"]
    },
    {
      "key"      = "kubernetes.io/arch"
      "operator" = "In"
      "values"   = ["amd64"]
    },
    {
      "key"      = "karpenter.sh/capacity-type"
      "operator" = "In"
      "values"   = ["on-demand"]
    },
    {
      "key"      = "karpenter.k8s.aws/instance-category"
      "operator" = "In"
      "values"   = ["c", "m", "r"]
    },
    {
      "key"      = "karpenter.k8s.aws/instance-generation"
      "operator" = "Gt"
      "values"   = ["2"]
    },
  ]
  requirements               = length(var.requirements) == 0 ? { "requirements" = local.default_requirements } : { "requirements" = var.requirements }
  labels                     = length(var.labels) == 0 ? {} : { "labels" = var.labels }
  taints                     = length(var.taints) == 0 ? {} : { "taints" = var.taints }
  annotations                = length(var.annotations) == 0 ? {} : { "annotations" = var.annotations }
  startup_taints             = length(var.startup_taints) == 0 ? {} : { "startupTaints" = var.startup_taints }
  resources_limits           = length(var.resources_limits) == 0 ? {} : { "limits" = { "resources" = var.resources_limits } }
  consolidation_enabled      = { "consolidation" = { "enabled" = var.consolidation_enabled } }
  ttl_secondes_after_empty   = var.ttl_secondes_after_empty == null ? {} : { "ttlSecondsAfterEmpty" = var.ttl_secondes_after_empty }
  ttl_seconds_untill_expierd = var.ttl_seconds_untill_expierd == null ? {} : { "ttlSecondsUntilExpired" = var.ttl_seconds_untill_expierd }
  weight                     = var.weight == null ? {} : { "weight" = var.weight }
  kubelet_configuration = { "kubeletConfiguration" = merge(
    local.cluster_dns,
    local.container_runtime,
    local.kubelet_system_reserved,
    local.kubelet_kube_reserved,
    local.kubelet_eviction_hard,
    local.kubelet_eviction_soft,
    local.kubelet_eviction_soft_grace_period,
    local.kubelet_eviction_max_pod_grace_period,
    local.kubelet_pods_per_core,
    local.kubelet_max_pods
    )
  }
  cluster_dns                           = length(var.cluster_dns) == 0 ? {} : { "clusterDNS" = var.cluster_dns }
  container_runtime                     = { "containerRuntime" = var.container_runtime }
  kubelet_system_reserved               = length(var.kubelet_system_reserved) == 0 ? {} : { "systemReserved" = var.kubelet_system_reserved }
  kubelet_kube_reserved                 = length(var.kubelet_kube_reserved) == 0 ? {} : { "kubeReserved" = var.kubelet_kube_reserved }
  kubelet_eviction_hard                 = length(var.kubelet_eviction_hard) == 0 ? {} : { "evictionHard" = var.kubelet_eviction_hard }
  kubelet_eviction_soft                 = length(var.kubelet_eviction_soft) == 0 ? {} : { "evictionSoft" = var.kubelet_eviction_soft }
  kubelet_eviction_soft_grace_period    = length(var.kubelet_eviction_soft_grace_period) == 0 ? {} : { "evictionSoftGracePeriod" = var.kubelet_eviction_soft_grace_period }
  kubelet_eviction_max_pod_grace_period = var.kubelet_eviction_max_pod_grace_period == null ? {} : { "evictionMaxPodGracePeriod" = var.kubelet_eviction_max_pod_grace_period }
  kubelet_pods_per_core                 = var.kubelet_pods_per_core == null ? {} : { "podsPerCore" = var.kubelet_pods_per_core }
  kubelet_max_pods                      = var.kubelet_max_pods == null ? {} : { "maxPods" = var.kubelet_max_pods }


  instace_profile       = var.instace_profile == null ? {} : { "instanceProfile" = var.instace_profile }
  tags                  = var.tags == length(var.tags) == 0 ? {} : { "tags" = var.tags }
  ami_selector          = length(var.ami_selector) == 0 ? {} : { "amiSelector" = var.ami_selector }
  user_data             = var.user_data == null ? {} : { "user_data" = var.ami_family == "Bottlerocket" ? var.user_data : local.user_data_al2_ubuntu }
  block_device_mappings = length(var.block_device_mappings) == 0 ? {} : { "blockDeviceMappings" = var.block_device_mappings }

}

resource "local_file" "provisioner" {
  count    = var.argocd_enabled ? 1 : 0
  content  = yamlencode(local.provisioner)
  filename = "${path.root}/${var.apps_dir}/${var.application_name}/${var.name}.yaml"
}
resource "local_file" "node_template" {
  count    = var.argocd_enabled ? 1 : 0
  content  = yamlencode(local.node_template)
  filename = "${path.root}/${var.apps_dir}/${var.application_name}/${var.name}-template.yaml"
}
resource "kubectl_manifest" "provisioner" {
  count     = var.argocd_enabled ? 0 : 1
  yaml_body = yamlencode(local.provisioner)
}
resource "kubectl_manifest" "node_template" {
  count     = var.argocd_enabled ? 0 : 1
  yaml_body = yamlencode(local.node_template)
}