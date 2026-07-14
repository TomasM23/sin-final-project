\# SIN Final Project



Projeto final de Sistemas de Informação na Nuvem.



\## Descrição



Este projeto implementa uma aplicação distribuída baseada numa arquitetura de microserviços e serviços cloud da AWS.



A aplicação é composta por três microserviços:



\- `catalog-service` — serviço responsável pelo catálogo.

\- `order-service` — serviço responsável pela criação de encomendas.

\- `notification-service` — serviço responsável pelo processamento assíncrono das encomendas.



\## Arquitetura



```text

&#x20;                   GitHub

&#x20;                      |

&#x20;                      v

&#x20;               GitHub Actions

&#x20;                      |

&#x20;                 OIDC / IAM

&#x20;                      |

&#x20;                      v

&#x20;                    AWS

&#x20;                      |

&#x20;             +--------+--------+

&#x20;             |                 |

&#x20;             v                 v

&#x20;            EC2               RDS

&#x20;             |              PostgreSQL

&#x20;             |

&#x20;   +---------+----------+

&#x20;   |         |          |

&#x20;   v         v          v

&#x20;Catalog    Order    Notification

&#x20;Service   Service      Service

&#x20; :8080     :8081

&#x20;             |

&#x20;             v

&#x20;         Amazon SQS

&#x20;             |

&#x20;             v

&#x20;     Notification Service

```



\## Serviços



\### Catalog Service



O `catalog-service` é executado num container Docker na instância EC2 e comunica com a base de dados PostgreSQL no Amazon RDS.



Porta utilizada:



```text

8080

```



Teste de saúde:



```bash

curl http://localhost:8080/health

```



\### Order Service



O `order-service` permite criar encomendas e enviar uma mensagem para uma fila Amazon SQS.



Porta utilizada:



```text

8081

```



Teste de saúde:



```bash

curl http://localhost:8081/health

```



Exemplo de criação de uma encomenda:



```bash

curl -X POST http://localhost:8081/orders \\

&#x20; -H "Content-Type: application/json" \\

&#x20; -d '{"product":"Teste","quantity":1}'

```



\### Notification Service



O `notification-service` funciona como consumidor da fila Amazon SQS.



Quando uma nova encomenda é enviada pelo `order-service`, o serviço recebe a mensagem, processa a encomenda e remove a mensagem da fila.



Os logs podem ser consultados através de:



```bash

sudo docker logs notification-service

```



\## Infraestrutura AWS



A infraestrutura foi criada utilizando Terraform.



Foram utilizados os seguintes serviços AWS:



\- Amazon VPC

\- Amazon EC2

\- Amazon RDS PostgreSQL

\- Amazon SQS

\- AWS IAM

\- IAM Roles

\- OpenID Connect (OIDC)



A aplicação utiliza uma VPC com subnets públicas e privadas.



A instância EC2 executa os microserviços em containers Docker.



A base de dados PostgreSQL é disponibilizada através do Amazon RDS.



O Amazon SQS permite a comunicação assíncrona entre o `order-service` e o `notification-service`.



\## Docker



Cada microserviço possui o seu próprio `Dockerfile`.



As imagens são construídas e publicadas no Docker Hub:



\- `tomasmatos023/catalog-service`

\- `tomasmatos023/order-service`

\- `tomasmatos023/notification-service`



Os containers são executados na instância EC2.



\## Ansible



O Ansible é utilizado para configurar automaticamente a instância EC2.



O playbook instala e configura os componentes necessários para executar a aplicação.



Teste de comunicação:



```bash

ansible all -i inventory.ini -m ping

```



Execução do playbook:



```bash

ansible-playbook -i inventory.ini playbook.yml

```



\## CI/CD



O projeto utiliza GitHub Actions para implementar um pipeline CI/CD.



Quando é realizado um push para a branch `main`, o pipeline executa automaticamente:



1\. Checkout do repositório.

2\. Autenticação na AWS através de OIDC.

3\. Login no Docker Hub.

4\. Build das imagens Docker.

5\. Push das imagens para o Docker Hub.

6\. Ligação SSH à instância EC2.

7\. Pull das novas imagens.

8\. Recriação dos containers.



A autenticação entre o GitHub Actions e a AWS utiliza OIDC, evitando a utilização de Access Keys permanentes.



\## Segurança



Foram aplicadas várias medidas de segurança:



\- Utilização de IAM Roles.

\- Autenticação OIDC entre GitHub Actions e AWS.

\- Secrets armazenados no GitHub Actions.

\- Base de dados executada no Amazon RDS.

\- Permissões IAM baseadas no princípio de menor privilégio.

\- Acesso ao Amazon SQS limitado à fila do projeto.

\- Branch `main` protegida através de Branch Protection Rules.



\## Branch Protection



A branch `main` está protegida.



As alterações devem ser realizadas numa branch separada e integradas através de Pull Request.



Os status checks do GitHub Actions devem ser concluídos com sucesso antes do merge.



\## Tecnologias utilizadas



\- AWS

\- Terraform

\- Ansible

\- Docker

\- Python

\- Flask

\- PostgreSQL

\- Amazon SQS

\- GitHub Actions

\- GitHub OIDC



\## Autor



Tomás Matos - a22209049

