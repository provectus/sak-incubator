# For depends_on queue
variable "module_depends_on" {
  default     = []
  type        = list(any)
  description = "A list of explicit dependencies"
}

variable "cluster_name" {
  type        = string
  default     = "null"
  description = "A name of the Amazon EKS cluster"
}

variable "namespace" {
  type        = string
  default     = ""
  description = "A name of the existing namespace"
}

variable "namespace_name" {
  type        = string
  default     = "cvat"
  description = "A name of namespace for creating"
}

variable "domains" {
  type        = list(string)
  default     = []
  description = "A list of domains to use for ingresses"
}

variable "cvat_postgresql_local" {
  default     = true
  description = "Internal database or external"
}

variable "cvat_postgresql_host" {
  default     = ""
  description = "external Postgresql host"
}

variable "cvat_postgresql_port" {
  default     = "5432"
  description = "external Postgresql port"
}

variable "cvat_postgresql_username" {
  default     = "postgresqluser"
  description = "external Postgresql username"
}

variable "cvat_postgresql_password" {
  default     = ""
  description = "external Postgresql password"
}

variable "cvat_postgresql_database" {
  default     = "cvat"
  description = "external Postgresql database"
}

variable "cvat_redis_local" {
  default     = "true"
  description = "internal redis or external"
}

variable "cvat_redis_host" {
  default     = ""
  description = "external redis host"
}

variable "cvat_redis_port" {
  default     = "6379"
  description = "external redis port"
}

variable "cvat_redis_username" {
  default     = "redisuser"
  description = "redis username"
}

variable "cvat_redis_password" {
  default     = ""
  description = "redis password"
}

variable "cvat_tag" {
  default     = "v1.3.0"
  description = "CVAT version tag"
}