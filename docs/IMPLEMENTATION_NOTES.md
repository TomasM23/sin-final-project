# Implementation notes

This archive contains a substantial DR implementation, but cloud-specific values still need to be supplied and tested in the target AWS account.

## Added

- Reusable regional Terraform stack for primary and standby.
- ALB health checks and Route 53 failover records.
- RDS Multi-AZ primary and optional cross-region read replica.
- Secrets Manager in both regions.
- Region-specific SQS/DLQ and IAM runtime roles.
- OIDC role module.
- Container CI, Terraform plan/apply pipeline and manual failover drill.
- RTO measurement artifact.
- DR runbook.
- Database persistence for orders.
- Environment/region-aware health endpoints.

## Expected test adjustments

- Existing Route 53 domain and hosted zone.
- Existing or newly created EC2 key pairs in each region.
- AWS quotas and permissions for two ALBs, RDS Multi-AZ and cross-region replica.
- Docker Hub image visibility and credentials.
- OIDC provider duplication if one already exists.
- Exact PostgreSQL cross-region replica compatibility in the account/selected regions.
