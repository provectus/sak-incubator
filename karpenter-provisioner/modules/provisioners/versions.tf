terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
  }
  required_version = ">= 1.1"
}