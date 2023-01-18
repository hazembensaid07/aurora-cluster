variable "ACESSKEY" {}
variable "SECRETKEY" {}
variable "region" {
  default = "eu-west-3"
}
variable "vpc_cidr" {}
variable "public_subnets_cidr" {}
variable "private_subnets_cidr" {}
variable "name-subnet-group" {
  description = "subnet group of dbs "
}

variable "sg-name" {
  description = "security group name "
}

variable "PORT" {
  description = "DB PORT  "
}
variable "INGRESS_CIDR_BLOCKS" {
  description = "INBOUND CIDR  "
}
variable "db-instance-class" {
  description = "db instance type  "
}

variable "db-username" {
  description = "db username  "
}
variable "db-password" {
  description = "db password  "
}
