module "vpc" {
  source = "../../../infrastructure/network"

  prefix = "dev"
  region = "us-west-1"
}