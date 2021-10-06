variable "values" {
  default     = {}
  description = "A values for Helm Chart"
}

variable "namespace" {
  type        = string
  default     = "default"
  description = "A name of the existing namespace"
}

variable "namespace_name" {
  type        = string
  default     = "application"
  description = "A name of namespace for creating"
}

variable "cluster_name" {
  type        = string
  default     = null
  description = "A name of the Amazon EKS cluster"
}

variable "chart_version" {
  default     = "0.1.0"
  description = "Version of Helm Chart"
}

variable "argocd" {
  type        = map(string)
  description = "A set of values for enabling deployment through ArgoCD"
  default     = {}
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A tags for attaching to new created AWS resources"
}

variable "repository" {
  type        = string
  description = "A repository of Helm Chart"
}

variable "chart" {
  type        = string
  description = "A Helm Chart name"
}

variable "name" {
  type        = string
  description = "A name of the application"
}

variable "iam_permissions" {
  type        = any
  default     = []
  description = "A list of IAM permissions required for application launch"
}

variable "service_account_name" {
  type        = string
  default     = ""
  description = "A name of the service account, in case of using custom SA name not matching with application name"
}

variable "irsa_annotation_field" {
  type        = string
  default     = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
  description = "A filed name for specifying IRSA annotation"
}

variable "destination_server" {
  type        = string
  default     = "https://kubernetes.default.svc"
  description = "A destination server for ArgoCD application"
}
