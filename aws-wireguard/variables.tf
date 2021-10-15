variable "instance_type" {
  default     = "t3.small"
  description = "Instance type which will be used by Wireguard VPN server, please note - it should have enhanced network support"
  type = string
}

variable "wg_group_name" {
  default = "wireguard"
  type    = string
  description = "AWS IAM group name, members of that group will be members of wireguard server"
}

variable "listen-port" {
  default = "51820"
  type    = string
}

variable "aws_ec2_key" {
  default     = null
  type        = string
  description = "EC2 key, if provided, ec2 Security group allow external access by 22 tcp port"
}

variable "project-name" {
  default = "vpn-service"
  type = string
}

variable "prefix" {
  default = "wireguard"
  type    = string
}

variable "vpc_cidr" {
  default     = "10.11.0.0/16"
  description = "The CIDR of VPC, specify if you wish create VPC with specific CIDR"
  type = string
}

variable "vpc_id" {
  default     = null
  description = "VPC ID, must be provided if you want to deploy Wireguard server in existing VPC"
  type = string
}

variable "wireguard_subnet" {
  default     = "10.11.0.0/24"
  description = "Subnet ID where wireguard server and management lambdas will be deployed"
  type = string
}

variable "vpn_subnet" {
  default     = "10.111.111.0/24"
  description = "VPN subnet, VPN clients will get internal IPs from this subnet"
  type = string
}

variable "wg_admin_email" {
  default = null
  type = string
  description = <<-EOT
If specified, this email will receive  wireguard configurations for all clients.
Configurations will be send by AWS SES. Please make sure that SES out of sandbox or admin email verified.
EOT
}