# SIN Final Project — Época Especial

Projeto de Sistemas de Informação na Nuvem com microserviços, Terraform, Docker, SQS, RDS, CI/CD e uma extensão obrigatória de **Automated Disaster Recovery & Multi-Region Failover**.

## Arquitetura

- Primary: `eu-west-1`
- Standby: `eu-central-1`
- Route 53 DNS failover
- ALB e health checks em cada região
- EC2 com containers Docker
- RDS PostgreSQL Multi-AZ no primary
- Read replica PostgreSQL cross-region opcional
- SQS e DLQ independentes por região
- Secrets Manager em ambas as regiões
- GitHub Actions autenticado por OIDC

```text
                     Route 53
                 failover DNS record
                         |
            +------------+------------+
            |                         |
     eu-west-1 PRIMARY          eu-central-1 STANDBY
            |                         |
           ALB                       ALB
            |                         |
           EC2                       EC2
       Docker services           Docker services
            |                         |
       SQS + DLQ                 SQS + DLQ
            |
     RDS Multi-AZ  ---- cross-region read replica ----> RDS standby
```

## Microserviços

- `catalog-service`: produtos persistidos no PostgreSQL, porta 8080.
- `order-service`: encomendas persistidas no PostgreSQL e eventos enviados para SQS, porta 8081.
- `notification-service`: consumidor assíncrono da fila SQS.

Os endpoints `/health` devolvem serviço, estado, ambiente e região para tornar o failover visível.

## Estrutura importante

```text
infrastructure/
  environments/dr/          # composição primary + standby
  modules/regional-stack/   # VPC, subnets, ALB, EC2, SQS, IAM
  modules/database-primary/
  modules/database-replica/
  modules/failover-dns/
  modules/github-oidc/
.github/workflows/
  ci.yml
  infrastructure-dr.yml
  failover-drill.yml
docs/dr.md
```

## GitHub Secrets

Criar estes secrets no repositório:

| Secret | Conteúdo |
|---|---|
| `AWS_ROLE_ARN` | ARN da role OIDC usada pelos workflows |
| `DOCKERHUB_USERNAME` | utilizador Docker Hub |
| `DOCKERHUB_TOKEN` | token Docker Hub |
| `HOSTED_ZONE_ID` | Hosted Zone ID do Route 53 |
| `DR_DOMAIN_NAME` | domínio completo, por exemplo `app.example.com` |
| `ADMIN_CIDR` | IP autorizado para SSH, por exemplo `1.2.3.4/32` |
| `PRIMARY_KEY_NAME` | key pair da região primary |
| `STANDBY_KEY_NAME` | key pair da região standby |
| `PRIMARY_INSTANCE_ID` | output da instância EC2 primary |
| `STANDBY_DB_INSTANCE_ID` | identificador RDS standby |
| `PRIMARY_REGION` | `eu-west-1` |
| `STANDBY_REGION` | `eu-central-1` |


## Pipelines

- `CI - Containers`: valida as imagens em PR e publica no Docker Hub em `main`.
- `Infrastructure DR`: executa format, init, validate e plan; em merge para `main` executa apply.
- `DR Failover Drill`: workflow manual que promove a réplica opcionalmente, para a EC2 primary, mede RTO, testa o standby e reinicia a EC2 primary.

## Testes

```bash
curl http://DOMINIO/health
curl http://DOMINIO/products
curl http://DOMINIO/orders
curl -X POST http://DOMINIO/orders \
  -H 'Content-Type: application/json' \
  -d '{"product":"Teste","quantity":1}'
```

