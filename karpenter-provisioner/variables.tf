variable "cluster_name" {
  type        = string
  description = "A name of the Amazon EKS cluster"
}
variable "application_name" {
  type        = string
  description = "A name of the Argocd application recource"
  default     = "provisioners"
}
variable "argocd" {
  type        = map(string)
  description = "A set of values for enabling deployment through ArgoCD"
  default = {
    repository = ""
    branch     = ""
    namespace  = ""
    path       = ""
    full_path  = ""
    kms_key_id = ""
    project    = ""
  }
}
variable "argocd_enabled" {
  type        = bool
  description = "A set of values for enabling deployment through ArgoCD"
  default     = true
}
variable "provisioners" {
  type    = any
  default = []
}