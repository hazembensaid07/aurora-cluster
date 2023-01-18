variable "name-subnet-group" {
  description = "subnet group of dbs "
}
variable "SUBNETS" {
  description = "subnets "
}
variable "sg-name" {
  description = "security group name "
}
variable "VPC_ID" {
  description = "vpc id "
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
variable "availability_zones" {
  description = "availability zones  "
}
variable "db-username" {
  description = "db username  "
}
variable "db-password" {
  description = "db password  "
}
