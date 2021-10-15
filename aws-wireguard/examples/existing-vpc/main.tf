terraform {
  required_providers {
    aws = {
      version = "~>3.59.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

module "aws-wireguard" {
  source           = "../.."
  instance_type    = "t3.micro"
  wg_group_name    = "wg-test-group"
  listen-port      = "8080"
  aws_ec2_key      = "asafin"
  prefix           = "wg"
  project-name     = "dev"
  vpc_id           = "vpc-d89be5b0"
  wireguard_subnet = "subnet-abb5f5c2"
  vpn_subnet       = "10.11.12.0/24"
  wg_admin_email = "azsafin@provectus.com"
}

output "get_config_command" {
  value = module.aws-wireguard.get_conf_command
}