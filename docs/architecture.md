# Arquitetura da Aplicação

## Visão Geral

A arquitetura da aplicação foi projetada para executar a API em ambiente de nuvem utilizando serviços da AWS, containers Docker e Kubernetes.

A solução utiliza:

* **Docker** para empacotamento da aplicação;
* **Amazon ECR** para armazenamento das imagens Docker;
* **Amazon EKS** para execução e orquestração dos containers;
* **Amazon RDS PostgreSQL** para persistência dos dados;
* **Application Load Balancer (ALB)** para encaminhamento do tráfego até a aplicação;
* **Amazon API Gateway** como ponto de entrada externo da API;
* **Terraform** para provisionamento da infraestrutura.

A aplicação é executada em um cluster Amazon EKS localizado em subnets privadas. O banco de dados PostgreSQL permanece separado do cluster Kubernetes e é executado utilizando Amazon RDS.

---

## Arquitetura Geral

O fluxo principal da aplicação é:

```text
                         Cliente
                            │
                            │ HTTPS
                            ▼
                   Amazon API Gateway
                            │
                            │ VPC Link
                            ▼
                  Internal Application
                     Load Balancer
                            │
                            │ HTTP :8000
                            ▼
                     EKS NodePort
                         :30080
                            │
                            ▼
                    Kubernetes Service
                         :8000
                            │
                            ▼
                    Django Pods :8000
                            │
                            │ PostgreSQL :5432
                            ▼
                    Amazon RDS
                     PostgreSQL
```

A autenticação possui um fluxo separado utilizando API Gateway e função serverless:

```text
Cliente
   │
   │ POST /auth
   ▼
API Gateway
   │
   ▼
AWS Lambda
   │
   ▼
Amazon RDS
```

---

# Componentes

## Aplicação

A API é executada em containers Docker.

A imagem da aplicação é construída a partir do código presente no repositório da aplicação e posteriormente publicada no Amazon ECR.

O container executa a aplicação Django disponibilizando a porta `8000`.

---

## Amazon ECR

O Amazon Elastic Container Registry (ECR) é utilizado para armazenar as imagens Docker da aplicação.

O processo de publicação da imagem segue o fluxo:

```text
Código da aplicação
        │
        ▼
    Docker Build
        │
        ▼
     Docker Image
        │
        ▼
      Amazon ECR
```

O ECR funciona como registro das imagens utilizadas pelo Kubernetes durante o deploy.

---

## Amazon EKS

O Amazon Elastic Kubernetes Service (EKS) é utilizado para executar e orquestrar os containers da aplicação.

O cluster possui um Managed Node Group responsável por executar os workloads Kubernetes.

O Kubernetes gerencia:

* Deployment;
* Pods;
* Service;
* Horizontal Pod Autoscaler;
* Job para execução das migrations;
* Health Checks.

A aplicação inicia com duas réplicas.

Os nodes do EKS são executados em subnets privadas.

---

## Kubernetes Deployment

O Deployment é responsável por manter as réplicas da aplicação em execução.

A configuração inicial utiliza:

* **2 réplicas**;
* Estratégia de atualização **RollingUpdate**;
* `maxSurge: 1`;
* `maxUnavailable: 0`.

Durante uma atualização, o Kubernetes substitui gradualmente os Pods antigos pelos novos, reduzindo a possibilidade de indisponibilidade da aplicação.

---

## Kubernetes Service

O Service fornece um ponto de acesso estável para os Pods da aplicação.

A aplicação utiliza um Service do tipo `NodePort`.

```text
ALB :8000
    │
    ▼
NodePort :30080
    │
    ▼
Service :8000
    │
    ▼
Django Pods :8000
```

O NodePort utilizado pela aplicação é `30080`.

---

## Application Load Balancer

A aplicação utiliza um **Application Load Balancer interno** para receber o tráfego proveniente do ambiente privado através do VPC Link.

O ALB encaminha as requisições para o NodePort dos nodes do EKS.

Configuração principal:

* Tipo: Application Load Balancer;
* Acesso: interno;
* Listener: HTTP `8000`;
* Target Group: instâncias do EKS;
* Porta do Target Group: `30080`;
* Health Check: `/health/ready/`.

O ALB é provisionado diretamente pelo Terraform.

Não é utilizado Kubernetes Ingress ou AWS Load Balancer Controller.

---

## Amazon API Gateway

O Amazon API Gateway funciona como ponto de entrada externo da API.

A comunicação externa utiliza HTTPS.

Para as rotas da aplicação, o API Gateway utiliza **VPC Link** para encaminhar as requisições ao ALB interno.

```text
Cliente
   │
   │ HTTPS
   ▼
API Gateway
   │
   │ VPC Link
   ▼
Internal ALB
   │
   ▼
EKS
```

Essa abordagem mantém o ALB e os nodes do EKS em ambiente privado, sem exposição direta à internet.

---

## Horizontal Pod Autoscaler

O Horizontal Pod Autoscaler (HPA) monitora a utilização média de CPU dos Pods e ajusta automaticamente a quantidade de réplicas da aplicação.

A configuração inicial possui:

* **Mínimo:** 2 Pods;
* **Máximo:** 6 Pods;
* **Meta de utilização de CPU:** 50%.

O HPA utiliza o Metrics Server para obter as métricas de utilização dos Pods.

```text
              HPA
               │
               ▼
        CPU média dos Pods
               │
       ┌───────┴───────┐
       ▼               ▼
   Aumenta          Reduz
    Pods             Pods
       │               │
       └───────┬───────┘
               ▼
          2 a 6 Pods
```

---

## Health Checks

A aplicação utiliza probes do Kubernetes para monitorar a disponibilidade dos containers.

São utilizadas:

* **Startup Probe:** verifica se a aplicação terminou sua inicialização;
* **Liveness Probe:** verifica se o container continua funcionando corretamente;
* **Readiness Probe:** verifica se o Pod está pronto para receber tráfego.

Os endpoints utilizados são:

```text
/health/live/
/health/ready/
```

O endpoint de readiness também é utilizado pelo Load Balancer para verificar a saúde das instâncias da aplicação.

---

## Migration Job

As migrations do banco de dados são executadas através de um Kubernetes Job.

O Job utiliza a mesma imagem da aplicação e executa:

```text
python manage.py migrate --noinput
```

O Job é executado separadamente do Deployment para evitar que cada réplica da aplicação execute migrations individualmente.

Após a conclusão, o recurso pode ser removido automaticamente através da configuração de TTL do Job.

---

## Amazon RDS

O banco de dados PostgreSQL é executado utilizando Amazon RDS.

O banco permanece separado do cluster Kubernetes.

```text
Amazon EKS
     │
     │ PostgreSQL :5432
     ▼
Amazon RDS
     │
     ▼
PostgreSQL
```

A comunicação entre a aplicação e o RDS ocorre através da rede privada da VPC.

O acesso ao banco é controlado através de Security Groups.

---

# Rede

A infraestrutura utiliza uma VPC com duas Availability Zones.

São utilizadas:

* 2 subnets públicas;
* 2 subnets privadas;
* Internet Gateway;
* 1 NAT Gateway;
* Security Groups.

A arquitetura de rede pode ser representada da seguinte forma:

```text
                         Internet
                            │
                            ▼
                    Internet Gateway
                            │
              ┌─────────────┴─────────────┐
              │                           │
       Public Subnet A             Public Subnet B
              │
              ▼
         NAT Gateway
              │
       ┌──────┴──────┐
       │             │
       ▼             ▼
Private Subnet A  Private Subnet B
       │             │
       └──────┬──────┘
              │
              ▼
             EKS
              │
              ▼
             RDS
```

As subnets privadas utilizam o NAT Gateway para acesso de saída à internet quando necessário.

A utilização de um único NAT Gateway foi adotada devido às restrições de custo e recursos do ambiente AWS Academy. Essa decisão representa uma limitação conhecida de alta disponibilidade e está documentada em ADR específico.

---

# Segurança

A comunicação entre os componentes é controlada por Security Groups.

As principais regras de comunicação são:

```text
API Gateway
     │
     │ VPC Link
     ▼
ALB :8000
     │
     │ TCP :30080
     ▼
EKS Nodes
     │
     │ TCP :5432
     ▼
RDS PostgreSQL
```

O ALB e os nodes do EKS permanecem em subnets privadas.

As credenciais e informações sensíveis não devem ser armazenadas diretamente nos manifests Kubernetes ou no código-fonte.

---

# Escalabilidade

A aplicação utiliza escalabilidade horizontal através do Kubernetes.

O HPA ajusta automaticamente a quantidade de Pods de acordo com a utilização média de CPU.

```text
              Aplicação
                  │
                  ▼
                 HPA
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
    Scale Up             Scale Down
        │                   │
        ▼                   ▼
   até 6 Pods           mínimo 2 Pods
```

Além da escalabilidade dos Pods, o EKS utiliza um Managed Node Group com capacidade de expansão dos nodes conforme a configuração definida na infraestrutura.

---

# Disponibilidade

A disponibilidade da aplicação é aumentada através de:

* Múltiplas réplicas;
* Distribuição dos workloads entre nodes;
* Rolling Updates;
* Startup Probe;
* Liveness Probe;
* Readiness Probe;
* Horizontal Pod Autoscaler;
* Duas Availability Zones.

A infraestrutura possui, entretanto, algumas limitações relacionadas ao ambiente AWS Academy, especialmente em relação à utilização de um único NAT Gateway.

---

# Fluxo de Deploy

O processo de CI/CD segue o fluxo:

```text
Código
   │
   ▼
Testes
   │
   ▼
Docker Build
   │
   ▼
Push da imagem
   │
   ▼
Amazon ECR
   │
   ▼
Amazon EKS
   │
   ▼
Rolling Update
   │
   ▼
Novos Pods
```

O repositório da aplicação é responsável pelo código, Docker e pipeline de CI/CD.

O repositório de infraestrutura Kubernetes é responsável pelo Terraform e pelos manifests Kubernetes.

---

# Infraestrutura como Código

A infraestrutura é provisionada utilizando Terraform.

Os principais recursos gerenciados incluem:

* VPC;
* Subnets;
* Internet Gateway;
* NAT Gateway;
* Route Tables;
* Security Groups;
* Amazon EKS;
* Managed Node Group;
* Amazon ECR;
* Application Load Balancer;
* Target Group;
* Listener;
* Recursos de rede necessários para comunicação entre os serviços.

Os recursos são organizados em repositórios separados de acordo com suas responsabilidades.

---

# Observabilidade

A aplicação e a infraestrutura são preparadas para integração com a solução de observabilidade definida para o projeto.

O monitoramento contempla:

* Métricas de CPU e memória;
* Saúde dos Pods;
* Health Checks;
* Disponibilidade da aplicação;
* Logs;
* Latência;
* Alertas.

O Kubernetes Metrics Server é utilizado para fornecer métricas de CPU e memória utilizadas pelo HPA.

A observabilidade complementar da aplicação e da infraestrutura é realizada através da solução de monitoramento definida no projeto.

---

# Responsabilidade dos Repositórios

A arquitetura utiliza repositórios separados para reduzir o acoplamento entre aplicação e infraestrutura.

| Repositório                       | Responsabilidade                                                                                     |
| --------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `tech-challenge-oficina`          | Código da API, Docker, CI/CD e observabilidade (monitoramento, logs, métricas, dashboards e alertas) |
| `tech-challenge-oficina-k8s`      | VPC, EKS, ECR, ALB, Terraform e manifests Kubernetes                                                 |
| `tech-challenge-oficina-database` | RDS PostgreSQL e configuração do banco                                                               |
| `tech-challenge-oficina-auth`     | API Gateway, Lambda e autenticação                                                                   |


---

# Tecnologias

* Python;
* Django;
* Docker;
* Kubernetes;
* Amazon EKS;
* Amazon ECR;
* Amazon RDS PostgreSQL;
* Amazon API Gateway;
* AWS Lambda;
* Application Load Balancer;
* Terraform;
* Metrics Server;
* New Relic.
