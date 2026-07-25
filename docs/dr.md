# Disaster Recovery Runbook

## Objetivo

Esta implementação usa **warm standby** em duas regiões AWS:

- Primary: `eu-west-1`
- Standby: `eu-central-1`

Cada região possui VPC, duas subnets públicas, duas privadas, EC2, ALB, SQS/DLQ e os três microserviços. O PostgreSQL principal é Multi-AZ e pode ter uma read replica cross-region. O Route 53 usa uma política de failover e verifica `GET /health` no ALB principal.

## RTO e RPO

- **RTO objetivo:** 180 segundos. Inclui deteção do health check, propagação DNS e resposta do ALB standby.
- **RPO objetivo:** até 60 segundos quando a read replica cross-region está ativa. O valor real depende do `ReplicaLag` medido no CloudWatch.

Estes são objetivos. Depois de cada drill, registar os números medidos na secção "Resultados".

## Pré-requisitos

1. Imagens `catalog-service`, `order-service` e `notification-service` publicadas no Docker Hub.
2. Hosted Zone pública no Route 53 e domínio configurado.
3. Role OIDC para GitHub Actions.
4. Backend Terraform S3/DynamoDB configurado, ou estado local apenas para testes.
5. Secrets do GitHub descritos no README.

## Provisionar

```bash
cd infrastructure/environments/dr
cp terraform.tfvars.example terraform.tfvars
# editar terraform.tfvars
terraform init
terraform fmt -recursive ../..
terraform validate
terraform plan
terraform apply
```

Ver outputs:

```bash
terraform output
terraform output -json primary
terraform output -json standby
```

## Teste manual antes do failover

```bash
curl http://DOMINIO/health
curl http://DOMINIO/products
curl http://DOMINIO/orders
```

A resposta de `/health` deve incluir:

```json
{"environment":"primary","region":"eu-west-1","status":"healthy"}
```

## Executar o drill automático

1. Abrir **GitHub Actions**.
2. Selecionar **DR Failover Drill**.
3. Clicar em **Run workflow**.
4. Manter `promote_database=true` para testar também escrita no standby.
5. Observar os passos e descarregar o artifact `dr-drill-*`.

O workflow:

1. guarda a hora inicial;
2. opcionalmente promove a read replica;
3. para a EC2 principal por AWS CLI;
4. consulta o domínio até receber `environment=standby`;
5. calcula o RTO;
6. testa leitura e escrita;
7. volta a iniciar a EC2 principal;
8. guarda um relatório como artifact.

Não existe qualquer clique na consola AWS durante o failover.

## Observar o failover

Em paralelo ao workflow:

```bash
watch -n 5 'curl -s http://DOMINIO/health'
```

Ou:

```bash
./scripts/check-failover.sh http://DOMINIO 600
```

No Route 53, o health check principal passa para unhealthy e o registo secundário passa a ser devolvido.

## Rollback e failback

Reiniciar a EC2 principal é automático no final do workflow. Contudo, **promover uma read replica é uma operação irreversível**: a instância promovida deixa de ser réplica.

Para um failback completo após promoção:

1. escolher qual base de dados passa a ser a nova fonte de verdade;
2. criar uma nova réplica a partir dessa base;
3. atualizar o secret da região que volta a ser standby;
4. validar os dados;
5. só depois voltar a permitir escrita no ambiente antigo.

Não executar um drill com promoção da base de dados em ambiente com dados importantes sem um plano de reconciliação.

## Medir o RPO

Antes do drill, criar uma encomenda marcada com timestamp:

```bash
curl -X POST http://DOMINIO/orders \
  -H 'Content-Type: application/json' \
  -d '{"product":"RPO-TEST-2026-01-01T12:00:00Z","quantity":1}'
```

Após o failover, confirmar quando esse registo aparece no standby. Também consultar a métrica CloudWatch `ReplicaLag`. O RPO medido é a diferença entre a última escrita confirmada no primary e a última escrita presente no standby.

## Resultados

| Data | RTO medido | RPO medido | Resultado | Observações |
|---|---:|---:|---|---|
| A preencher | — | — | — | — |

## Controlo de custos

A solução é warm standby e cria recursos pagos em duas regiões. Para reduzir custos durante desenvolvimento:

- definir `enable_cross_region_read_replica = false` enquanto se testa VPC/EC2/ALB;
- destruir a infraestrutura quando não estiver a ser usada;
- usar instâncias `t3.micro`;
- manter apenas uma EC2 por região;
- consultar o AWS Budgets.

```bash
terraform destroy
```
