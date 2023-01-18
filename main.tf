provider "aws" {
  region     = var.region
  access_key = var.ACESSKEY
  secret_key = var.SECRETKEY

}
locals {
  production_availability_zones = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
}
module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  availability_zones   = local.production_availability_zones
}

module "db" {
  source              = "./modules/aurora"
  name-subnet-group   = var.name-subnet-group
  SUBNETS             = module.vpc.private_subnets_id
  sg-name             = var.sg-name
  VPC_ID              = module.vpc.vpc_id
  PORT                = var.PORT
  INGRESS_CIDR_BLOCKS = var.INGRESS_CIDR_BLOCKS
  db-instance-class   = var.db-instance-class
  availability_zones  = local.production_availability_zones
  db-username         = var.db-username
  db-password         = var.db-password
}
