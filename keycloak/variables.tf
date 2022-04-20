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
  default     = ""
  description = "A name of the existing namespace"
}

variable "namespace_name" {
  type        = string
  default     = "keycloak"
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

variable "domains" {
  type        = list(string)
  default     = ["local"]
  description = "A list of domains to use for ingresses"
}

variable "chart_version" {
  type        = string
  description = "A Helm Chart version"
  default     = "3.1.1"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A tags for attaching to new created AWS resources"
}

variable "keycloak_password" {
  type        = string
  description = "Password for keycloak admin"
  default     = ""
}

variable "keycloak_google_auth" {
  type        = string
  description = "Enables Google auth for keycloak"
  default     = false
}

variable "keycloak_client_id" {
  type        = string
  description = "The id of the client for keycloak Google auth"
  default     = ""
}

variable "keycloak_client_secret" {
  type        = string
  description = "The token of the client for keycloak Google auth"
  default     = ""
}

variable "keycloak_allowed_domains" {
  type        = string
  description = "Allowed domain for keycloak Google auth"
  default     = "local"
}