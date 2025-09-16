terraform {
  backend "s3" {
    bucket         = "terraform-qwist-state"
    key            = "k8s-tech-challenge/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-qwist"
    encrypt        = true
  }
}
