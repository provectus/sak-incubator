terraform {
  required_providers {
    aws = {
      version = "~>3.59.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

module "aws-wireguard" {
  source = "../.."
}

output "get_config_command" {
  value = module.aws-wireguard.get_conf_command
}