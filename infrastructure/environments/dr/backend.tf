terraform {
  backend "s3" {
    bucket       = "sin-final-project-tfstate-595658221962"
    key          = "environments/dr/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}