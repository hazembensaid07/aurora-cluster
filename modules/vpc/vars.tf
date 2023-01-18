variable "vpc_cidr" {
  description = "cidr block of the vpc"
}
variable "public_subnets_cidr" {
  description = "array of cidr to be associated to the public subnets"
}
variable "availability_zones" {
  description = "the availability zones"
}
variable "private_subnets_cidr" {
  description = "array of cidr to be associated to the private subnets"
}
