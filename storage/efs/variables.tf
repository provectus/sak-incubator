variable "aws_region" {
  type        = string
  description = "AWS region name"
}

variable "chart_name" {
  type        = string
  description = "Name of CSI driver chart"
  default     = "aws-efs-csi-driver"
}

variable "chart_version" {
  type        = string
  description = "Chart version"
  default     = "2.2.0"
}

variable "cluster_name" {
  type        = string
  description = "A name of the EKS cluster"
}

variable "namespace" {
  type        = string
  default     = "kube-system"
  description = "Kubernetes namespace name for PV/PVC"
}

variable "conf" {
  type        = map(string)
  description = "A custom configuration for deployment"
  default     = {}
}

variable "argocd" {
  type        = map(string)
  description = "A set of values for enabling deployment through ArgoCD"
  default     = {}
}

variable "efs_name" {
  type        = string
  description = "A name of the EFS storage"
}

variable "efs_permissions" {
  type        = string
  default     = "700"
  description = "EFS directory permissions"
}

variable "mount_options" {
  type        = list(string)
  default     = []
  description = "A list of mount options"
}

variable "pvc_name" {
  type        = string
  default     = "efs-pvc"
  description = "A name of the Persistent Volume Claim"
}

variable "pvc_size" {
  type        = string
  default     = "5Gi"
  description = "A size of the Persistent Volume Claim"
}

variable "tags" {
  type        = map(string)
  description = "Tags to add to AWS resources"
  default     = {}
}
