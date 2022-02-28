terraform {
  backend "s3" {
      bucket = "joe-demobucket-training"
      key = "global/s3/terraform.tfstate"
      region = "eu-west-3"     
  }

}