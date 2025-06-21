terraform {
  backend "s3" {
    bucket  = "nodejs-state-bucket"
    key     = "nodejs-project/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}