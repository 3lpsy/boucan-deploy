variable "aws_access_key_id" {
}

variable "aws_secret_access_key" {
}

variable "admin_email" {
}

variable "admin_password" {
}

variable "ami" {
  default = "ami-0234f00648a787ec1" # change me / built via packer
}

variable "acme_server_url" {
  default = "https://acme-v02.api.letsencrypt.org/directory"
  # default = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "instance_type" {
  default = "t2.small" # change me
}

variable "dns_root" {
}

variable "dns_sub" {
  default = "app"
}

variable "dns_dashboard_sub" {
  default = "dash"
}

variable "trusted_external_cidr_block" {
  type = list(string)
}

variable "wireguard_port" {
  default = 36283
}

variable "internet_cidr_block" {
}

variable "aws_default_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.20.0.0/16"
}

variable "upstream_dns_server" {
  default = "149.112.112.112"
}

