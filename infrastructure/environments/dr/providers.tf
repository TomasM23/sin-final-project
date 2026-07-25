provider "aws" {
  alias  = "primary"
  region = var.primary_region

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "standby"
  region = var.standby_region

  default_tags {
    tags = local.common_tags
  }
}
