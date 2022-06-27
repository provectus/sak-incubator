variable "aws_private" {
  type        = bool
  description = "Set true or false to use private or public infrastructure"
  default     = false
}

variable "argocd" {
  type        = map(string)
  description = "A set of values for enabling deployment through ArgoCD"
  default     = {}
}

variable "conf" {
  type        = map(string)
  description = "A custom configuration for deployment"
  default     = {}
}

variable "namespace" {
  type        = string
  default     = "kube-system"
  description = "A name of the existing namespace"
}

variable "namespace_name" {
  type        = string
  default     = "kube-system"
  description = "A name of namespace for creating"
}

variable "module_depends_on" {
  default     = []
  type        = list(any)
  description = "A list of explicit dependencies"
}

variable "cluster_name" {
  type        = string
  default     = null
  description = "A name of the Amazon EKS cluster"
}

variable "chart_version" {
  type        = string
  description = "A Helm Chart version"
  default     = "2.6.9"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A tags for attaching to new created AWS resources"
}