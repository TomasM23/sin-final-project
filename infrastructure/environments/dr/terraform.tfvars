project_name       = "sin-final-project"
primary_region     = "eu-west-1"
standby_region     = "eu-central-1"
dockerhub_username = "tomasmatos023"
image_tag          = "latest"
admin_cidr         = "85.246.99.185/32"

# Key pairs are region-specific. Create one in each region or leave empty.
key_name_primary = "sin-final-project-key"
key_name_standby = "sin-final-project-key-standby"

hosted_zone_id = ""
domain_name    = ""

# GitHub OIDC role. Set false when an OIDC provider already exists in the account.
create_github_oidc = false
github_repository  = "OWNER/REPOSITORY"

# Cost control: set false while initially testing the rest of the infrastructure.
enable_cross_region_read_replica = true
