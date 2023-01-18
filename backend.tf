terraform {
  backend "s3" {
    bucket = "terraform-state-aww"
    key    = "terraform/aurora-work"
    region = "eu-west-3"

  }
}
