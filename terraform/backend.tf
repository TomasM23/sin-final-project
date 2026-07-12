terraform {
  backend "s3" {
    bucket         = "sin-final-project-tf-state-a22209049"
    key            = "envs/dev/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "sin-final-project-tf-locks"
    encrypt        = true
  }
}