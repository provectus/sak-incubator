variable "cluster_name" {
  type        = string
  description = "A name of the EKS cluster"
}

variable "chart_version" {
  type        = string
  description = "A Helm Chart version"
  default     = "0.17.0"
}

variable "chart_name" {
  type        = string
  default     = "hashicorp-vault"
  description = "A chart name for vault installation"
}

variable "chart_namespace" {
  type        = string
  default     = "default"
  description = "A namespace for vault installation"
}

variable "chart_create_namespace" {
  type        = bool
  default     = false
  description = "A option for creating Kubernetes namespace"
}

variable "conf" {
  type        = map(string)
  description = "A custom configuration for deployment"
  default     = {}
}

# https://www.vaultproject.io/docs/configuration/storage/s3
variable "s3_storage" {
  type        = bool
  default     = false
  description = "A option to use Vault S3 storage type"
}

variable "s3_create_bucket" {
  type        = bool
  default     = false
  description = "A option for creating S3 bucket"
}

variable "s3_bucket_name" {
  type        = string
  default     = "swiss-army-kube-test-vault"
  description = "A bucket name for Vault S3 storage type"
}

variable "s3_bucket_region" {
  type        = string
  default     = "eu-north-1"
  description = "AWS region name for S3 bucket"
}

variable "file_storage" {
  type        = bool
  default     = false
  description = "A option to use Vault file storage type (local pod storage or EFS)"
}

variable "file_storage_name" {
  type        = string
  default     = "efs"
  description = "A volume name for Vault file storage type"
}

variable "file_storage_pvc_name" {
  type        = string
  default     = "efs-pvc"
  description = "PVC name for Vault file storage type"
}

variable "argocd" {
  type        = map(string)
  description = "A set of values for enabling deployment through ArgoCD"
  default     = {}
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for AWS object"
}
