data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

#This provider will be used to configure EventBridge,
# EventBridge consume CloudWatch events from region where IAM events logged, send them to SNS->Lambda
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

data "aws_vpc" "existed" {
  id    = var.vpc_id
  count = var.vpc_id != null ? 1 : 0
}

data "external" "is-wg-group-exist" {
  query   = {
    group_name = var.wg_group_name
  }
  program = ["${path.module}/scripts/check-iam-group.sh"]
}

locals {
  name               = "${var.prefix}-${var.project-name}"
  region             = data.aws_region.current.name
  account            = tostring(data.aws_caller_identity.current.account_id)
  vpc_id             = var.vpc_id != null ?  var.vpc_id : module.vpc.vpc_id
  prefix             = "/${var.prefix}/${var.project-name}"
  wg_ssm_config      = "/${var.prefix}/${var.project-name}/wg-config"
  wg_ssm_instance_id = "/${var.prefix}/${var.project-name}/instance_id"
  wg_ssm_user_prefix = "/${var.prefix}/${var.project-name}/users"
  wg_vpc_id          = var.vpc_id != null ? var.vpc_id : module.vpc.vpc_id
  wg_subnet          = var.vpc_id != null ?  var.wireguard_subnet : module.vpc.public_subnets[0]
}

resource "aws_iam_group" "wireguard" {
  count = data.external.is-wg-group-exist.result.exist == "true" ? 0 : 1
  name  = var.wg_group_name
}

module "vpc" {
  create_vpc                     = var.vpc_id != null ? false : true
  source                         = "terraform-aws-modules/vpc/aws"
  version                        = "3.2.0"
  name                           = local.name
  cidr                           = var.vpc_cidr
  azs                            = data.aws_availability_zones.available.names
  public_subnets                 = [var.wireguard_subnet]
  manage_default_route_table     = true
  default_route_table_tags       = { DefaultRouteTable = true }
  enable_dns_hostnames           = true
  enable_dns_support             = true
  enable_classiclink             = false
  enable_classiclink_dns_support = false
  create_egress_only_igw         = true
  create_igw                     = true #for public subnets
  enable_nat_gateway             = false
  single_nat_gateway             = false
  manage_default_security_group  = false
}

