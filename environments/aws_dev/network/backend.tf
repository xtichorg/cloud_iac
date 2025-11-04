terraform {
  backend "s3" {
    bucket = "tf-state-bucket-iac"
    key          = "xtichorg/dev_network/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}