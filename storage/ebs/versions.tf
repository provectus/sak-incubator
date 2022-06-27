terraform {
  required_version = ">= 0.15"

  required_providers {
    aws        = ">= 3.0"
    helm       = ">= 1.0"
    kubernetes = ">= 1.11"
    random     = ">= 3.1.0"
    local      = ">= 2.1.0"
  }
}