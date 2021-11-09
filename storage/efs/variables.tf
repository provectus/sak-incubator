variable "aws_region" {
  type        = string
  description = "AWS region name"
}

variable "cluster_name" {
  type        = string
  description = "A name of the EKS cluster"
}

variable "chart_namespace" {
  type        = string
  default     = "default"
  description = "Kubernetes namespace name for PV/PVC"
}

variable "chart_create_namespace" {
  type        = bool
  default     = false
  description = "A option for creating Kubernetes namespace"
}

variable "efs_name" {
  type        = string
  description = "A name of the EFS storage"
}

variable "efs_owner_uid" {
  type        = string
  default     = "1000"
  description = "A User ID for EFS configuration"
}

variable "efs_owner_gid" {
  type        = string
  default     = "1000"
  description = "A Group ID for EFS configuration"
}

variable "efs_folder_path" {
  type        = string
  default     = "/shared_folder"
  description = "A folder path inside EFS"
}

variable "efs_folder_permissions" {
  type        = string
  default     = "775"
  description = "A folder permissions in EFS"
}

variable "pv_name" {
  type        = string
  default     = "efs-pv"
  description = "A name of the Persistent Volume"
}

variable "pv_size" {
  type        = string
  default     = "5Gi"
  description = "A size of the Persistent Volume"
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
