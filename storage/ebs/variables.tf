variable "cluster_name" {
  type        = string
  description = "Name of the kubernetes cluster"
}

variable "vpc_id" {
  type        = string
  description = "domain name for ingress"
}

# variable "certificates_arns" {
#   type        = list(string)
#   description = "List of certificates to attach to ingress"
#   default     = []
# }

# variable "cluster_oidc_url" {
#   type        = string
#   description = "Cluster OpenID Connect URL"
# }