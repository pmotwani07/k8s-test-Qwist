terraform {
  backend "s3" {
    bucket = "REPLACE_WITH_YOUR_TFSTATE_BUCKET"
    key    = "k8s-tech-challenge/terraform.tfstate"
    region = "eu-central-1"
    dynamodb_table = "REPLACE_WITH_YOUR_LOCK_TABLE"
    encrypt = true
  }
}
