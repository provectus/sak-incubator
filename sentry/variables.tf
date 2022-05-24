variable "cluster_name" {
  type        = string
  default     = null
  description = "A name of the Amazon EKS cluster"
}

variable "argocd" {
  type        = map(string)
  description = "A set of values for enabling deployment through ArgoCD"
  default     = {}
}

variable "namespace" {
  type        = string
  default     = ""
  description = "A name of the existing namespace"
}

variable "namespace_name" {
  type        = string
  default     = "sentry"
  description = "A name of namespace for creating"
}

variable "module_depends_on" {
  default     = []
  type        = list(any)
  description = "A list of explicit dependencies"
}

variable "kubeversion" {
  type        = string
  description = "A Kubernetes API version"
  default     = "1.21"
}

variable "chart_version" {
  type        = string
  description = "A Helm Chart version"
  default     = "14.1.0"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A tags for attaching to new created AWS resources"
}

variable "conf" {
  type        = map(string)
  description = "A custom configuration for deployment"
  default     = {}
}

variable "ingress_annotations" {
  type        = map(string)
  description = "A set of annotations for Hydrosphere Ingress"
  default = {
    "kubernetes.io/ingress.class"           = "nginx"
    "nginx.ingress.kubernetes.io/use-regex" = "true"
  }
}

variable "domain" {
  type        = string
  default     = ""
  description = "A domain name to use for ingresses"
}
