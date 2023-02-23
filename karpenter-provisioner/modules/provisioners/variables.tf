variable "application_name" {
  type        = string
  description = "A name of the Argocd application recource"
}
variable "argocd_enabled" {
  type        = bool
  description = "A set of values for enabling deployment through ArgoCD"
  default     = true
}
variable "apps_dir" {
  type        = string
  description = "A folder for ArgoCD apps"
  default     = "apps"
}
variable "name" {
  type        = string
  description = " A name of the Karpenter provisioner and AWSNodeTemplae"
}
variable "requirements" {
  type = list(object({
    key      = string
    operator = string
    values   = list(string)
  }))
  validation {
    condition     = var.requirements == [] ? true : alltrue([for i in var.requirements : contains(["In", "NotIn", "Exists", "DoesNotExist", "Gt", "Lt"], i.operator)])
    error_message = "Valid operator is one of the following: In , NotIn , Exists , DoesNotExist , Gt , Lt."
  }
  description = "Requirements are layered with Labels and applied to every node."
  default     = []
}
variable "taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  validation {
    condition     = var.taints == [] ? true : alltrue([for i in var.taints : contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], i.effect)])
    error_message = "Valid value is one of the following: NoSchedule , NoExecute , PreferNoSchedule."
  }
  description = "Taints will be added to provisioned nodes"
  default     = []
}
variable "startup_taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  validation {
    condition     = var.startup_taints == [] ? true : alltrue([for i in var.startup_taints : contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], i.effect)])
    error_message = "Valid value is one of the following: NoSchedule , NoExecute , PreferNoSchedule."
  }
  description = "Startup taints will be added to provisioned nodes"
  default     = []
}
variable "labels" {
  type        = map(any)
  description = "Labels are arbitrary key-values that are applied to all nodes"
  default     = {}
}
variable "annotations" {
  type        = map(any)
  description = "Annotations are arbitrary key-values that are applied to all nodes"
  default     = {}
}
variable "container_runtime" {
  type        = string
  description = "You can specify the container runtime to be either dockerd or containerd.containerd is the only valid container runtime when using the Bottlerocket AMI Family or when using the AL2 AMI Family and K8s version 1.24+"
  validation {
    condition     = contains(["containerd", "dockerd"], var.container_runtime)
    error_message = "Valid value is one of the following: containerd , dockerd."
  }
  default = "containerd"
}
variable "cluster_dns" {
  type        = list(string)
  description = "specify cluster dns"
  default     = []
}
variable "kubelet_system_reserved" {
  type        = map(any)
  description = "Override the --system-reserved configuration"
  default     = {}
}
variable "kubelet_kube_reserved" {
  type        = map(any)
  description = "Override the --kube-reserved configuration"
  default     = {}
}
variable "kubelet_eviction_hard" {
  type        = map(any)
  description = "A hard eviction threshold has no grace period. When a hard eviction threshold is met, the kubelet kills pods immediately without graceful termination to reclaim the starved resource."
  default     = {}
}
variable "kubelet_eviction_soft" {
  type        = map(any)
  description = "A soft eviction threshold pairs an eviction threshold with a required administrator-specified grace period. The kubelet does not evict pods until the grace period is exceeded. The kubelet returns an error on startup if there is no specified grace period."
  default     = {}
}
variable "kubelet_eviction_soft_grace_period" {
  type        = map(any)
  description = "A set of eviction grace periods that define how long a soft eviction threshold must hold before triggering a Pod eviction."
  default     = {}
}
variable "kubelet_eviction_max_pod_grace_period" {
  type        = string
  description = "the administrator-specified maximum pod termination grace period to use during soft eviction."
  default     = null
}
variable "kubelet_pods_per_core" {
  description = "This value will also be passed through to the --pods-per-core value on kubelet startup to configure the number of allocatable pods the kubelet can assign to the node instance."
  type        = string
  default     = null
}
variable "kubelet_max_pods" {
  description = "This value will be used during Karpenter pod scheduling and passed through to --max-pods on kubelet startup."
  type        = string
  default     = null
}
variable "resources_limits" {
  type        = map(any)
  description = "constrains the maximum amount of resources that the provisioner will manage."
  default     = {}
}
variable "consolidation_enabled" {
  type        = bool
  description = "You can configure Karpenter to deprovision instances through your Provisioner in multiple ways. You can use var.ttl_seconds_untill_expierd, var.ttl_secondes_after_empty or var.consolidation_enabled."
  default     = true
}
variable "ttl_secondes_after_empty" {
  type        = number
  description = "node will be deprovisioned if it is empty after given secondes.consolidation should be disabled"
  default     = null
}
variable "ttl_seconds_untill_expierd" {
  type        = number
  description = "node will be deprovisioned after given secondes.consolidation should be disabled"
  default     = null
}
variable "weight" {
  type        = number
  description = "Priority given to the provisioner when the scheduler considers which provisioner to select. Higher weights indicate higher priority when comparing provisioners."
  default     = null
}
variable "ami_family" {
  type        = string
  description = "optional, resolves a default ami and userdata. Currently, Karpenter supports amiFamily values AL2, Bottlerocket, Ubuntu and Custom. GPUs are only supported with AL2 and Bottlerocket."
  default     = "AL2"
  validation {
    condition     = contains(["AL2", "Bottlerocket", "Ubuntu", "Custom"], var.ami_family)
    error_message = "Valid value is one of the following: AL2 , Bottlerocket , Ubuntu , Custom ."
  }
}
variable "block_device_mappings" {
  type = list(object({
    deviceName = string
    ebs = object({
      volumeSize          = string
      volumeType          = optional(string)
      iops                = optional(number)
      encrypted           = optional(bool)
      kmsKeyID            = optional(string)
      deleteOnTermination = optional(bool)
      throughput          = optional(number)
      snapshotID          = optional(string)
    })
  }))
  description = "Used to control the Elastic Block Storage (EBS) volumes that Karpenter attaches to provisioned nodes. "
  default     = []
}
variable "metadata_options" {
  type        = map(any)
  description = "Configures IMDS for the instance"
  default     = {}
}
variable "instace_profile" {
  type        = string
  description = "Overrides the node's identity from global settings"
  default     = null
}
variable "detailed_monitoring_enabled" {
  type        = bool
  description = "Configures detailed monitoring for the instance"
  default     = false
}
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Propagates tags to underlying EC2 resources"
}
variable "subnet_selector" {
  type        = map(string)
  default     = {}
  description = "Discovers tagged subnets to attach to instances"
}
variable "sg_selector" {
  type        = map(string)
  default     = {}
  description = "Discovers tagged security groups to attach to instances"
}
variable "ami_selector" {
  type        = map(string)
  default     = {}
  description = "Discovers tagged amis to override the amiFamily's default"
}
variable "user_data" {
  type        = string
  description = "You can control the UserData that is applied to your worker nodes via this field."
  default     = null
}