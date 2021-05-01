variable "argocd" {
  type        = map(string)
  description = "A set of values for enabling deployment through ArgoCD"
}

variable "conf" {
  type        = map(string)
  description = "A custom configuration for deployment"
  default     = {}
}

# For depends_on queqe
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

variable "grafana_loki_password" {
  type        = string
  description = "Password for grafana admin"
  default     = ""
}

variable "domains" {
  type        = list(string)
  default     = []
  description = "A list of domains to use for ingresses"
}

variable "namespace" {
  type        = string
  default     = ""
  description = "A name of the existing namespace"
}

variable "namespace_name" {
  type        = string
  default     = "logging"
  description = "A name of namespace for creating"
}

#pumped chart version
variable "chart_version" {
  type        = string
  description = "A Helm Chart version"
  default     = "2.0.0"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A tags for attaching to new created AWS resources"
}
