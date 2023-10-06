variable "name" {}
variable "cluster_name" {}
variable "private_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "region" {
  default = "us-east-1"
}

variable "consul_token" {
  default = "root"
}

variable "remote_principal" {
  description = "Account ID for sharing Route53 resolver to"
}