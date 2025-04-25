variable "vpc_name" {}
variable "vpc_cidr" {}
variable "public_subnets" {
  type = list(object({ cidr = string, az = string, name = string }))
}
variable "isolated_subnets" {
  type = list(object({ cidr = string, az = string, name = string }))
}
