# Tech Challenge Oficina — Infraestrutura Kubernetes

Infraestrutura como Código (IaC) e configuração Kubernetes da **Fase 3 do Tech Challenge FIAP**.

Este repositório é responsável pelo provisionamento da infraestrutura necessária para executar a API da oficina na AWS e pelos manifests Kubernetes utilizados para executar, escalar e manter a aplicação.

---

# Sobre o projeto

O projeto **Tech Challenge Oficina** consiste na evolução de uma aplicação de gerenciamento de oficina mecânica.

Nesta fase, a arquitetura foi evoluída para atender requisitos relacionados a:

* Escalabilidade;
* Alta disponibilidade;
* Conteinerização;
* Orquestração de containers;
* Infraestrutura como Código;
* Banco de dados gerenciado;
* Segurança;
* Monitoramento e observabilidade;
* Integração contínua e entrega contínua.

A infraestrutura utiliza **AWS, Docker, Kubernetes e Terraform**.

Este repositório concentra a responsabilidade pela infraestrutura Kubernetes e pelos recursos AWS relacionados à execução da aplicação.

---

# Arquitetura

A aplicação utiliza uma arquitetura baseada em Amazon API Gateway, VPC Link, Application Load Balancer, Amazon EKS e Amazon RDS.

O fluxo principal da aplicação é:

```text
                         Cliente
                            │
                            │ HTTPS
                            ▼
                   ┌─────────────────┐
                   │  API Gateway    │
                   └────────┬────────┘
                            │
                            │ VPC Link
                            ▼
                   ┌─────────────────┐
                   │  Internal ALB  │
                   │     :8000      │
                   └────────┬────────┘
                            │
                            │ Target Group :30080
                            ▼
                   ┌─────────────────┐
                   │   EKS Nodes     │
                   │  NodePort 30080 │
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ K8s Service     │
                   │     :8000       │
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │ Django Pods     │
                   │     :8000       │
                   └────────┬────────┘
                            │
                            │ PostgreSQL :5432
                            ▼
                   ┌─────────────────┐
                   │   Amazon RDS    │
                   │   PostgreSQL    │
                   └─────────────────┘
```

O **API Gateway** funciona como ponto de entrada externo da aplicação.

O **VPC Link** permite que o API Gateway encaminhe as requisições para o ALB interno.

O **Application Load Balancer** encaminha o tráfego para o Target Group configurado com os nodes do EKS através da porta `30080`.

O Kubernetes Service recebe o tráfego através do NodePort e distribui as requisições entre os Pods disponíveis.

O banco de dados permanece separado do cluster Kubernetes e é executado utilizando Amazon RDS PostgreSQL.

---

# Fluxo da imagem Docker

A imagem da aplicação é construída no pipeline de CI/CD e armazenada no Amazon ECR.

```text
Código da aplicação
        │
        ▼
       GitHub
        │
        ▼
       CI/CD
        │
        ▼
    Docker Build
        │
        ▼
   Docker Image
        │
        ▼
     Amazon ECR
        │
        ▼
     Amazon EKS
        │
        ▼
    Django Pods
```

O repositório da aplicação é responsável pelo código, Docker e pipeline de CI/CD.

Este repositório fornece a infraestrutura necessária para que a imagem seja executada no EKS.

---

# Serviços AWS

A infraestrutura utiliza os seguintes serviços:

| Serviço                   | Responsabilidade                                                   |
| ------------------------- | ------------------------------------------------------------------ |
| Amazon VPC                | Isolamento e configuração da rede                                  |
| Amazon EKS                | Cluster Kubernetes gerenciado                                      |
| Amazon EC2                | Nodes utilizados pelo cluster EKS                                  |
| Amazon ECR                | Armazenamento das imagens Docker                                   |
| Application Load Balancer | Distribuição interna do tráfego para a aplicação                   |
| NAT Gateway               | Acesso de saída à internet para recursos privados                  |
| Internet Gateway          | Conectividade da VPC com a internet                                |
| Amazon RDS                | Banco de dados PostgreSQL                                          |
| AWS IAM                   | Gerenciamento das permissões e roles utilizadas pelos serviços AWS |

---

# Infraestrutura como Código

A infraestrutura é provisionada utilizando **Terraform**.

Os principais recursos gerenciados neste repositório são:

* VPC;
* Subnets públicas;
* Subnets privadas;
* Internet Gateway;
* NAT Gateway;
* Route Tables;
* Security Groups;
* Application Load Balancer;
* Target Group;
* Listener;
* Amazon ECR;
* Amazon EKS;
* Managed Node Group.

O Terraform permite que a infraestrutura seja definida como código, facilitando sua reprodução, manutenção e versionamento.

---

# Rede

A infraestrutura utiliza uma VPC dedicada:

```text
VPC
10.0.0.0/16
│
├── Public Subnet A
│   └── 10.0.1.0/24
│
├── Public Subnet B
│   └── 10.0.2.0/24
│
├── Private Subnet A
│   └── 10.0.11.0/24
│
└── Private Subnet B
    └── 10.0.12.0/24
```

A infraestrutura utiliza duas Availability Zones para aumentar a disponibilidade dos recursos.

As subnets públicas possuem acesso ao Internet Gateway e são utilizadas para recursos que precisam de conectividade pública, como o NAT Gateway.

As subnets privadas são utilizadas pelos recursos do EKS.

O fluxo de saída das subnets privadas é:

```text
                    Internet
                       │
                       ▼
              Internet Gateway
                       │
                       ▼
                Public Subnet A
                       │
                       ▼
                  NAT Gateway
                       │
              ┌────────┴────────┐
              │                 │
              ▼                 ▼
       Private Subnet A   Private Subnet B
              │                 │
              └────────┬────────┘
                       │
                       ▼
                      EKS
```

---

# NAT Gateway e AWS Academy

A infraestrutura utiliza **um único NAT Gateway** compartilhado pelas duas subnets privadas.

Essa decisão foi tomada considerando as restrições de custo e recursos do ambiente **AWS Academy**.

A utilização de um NAT Gateway por Availability Zone proporcionaria maior disponibilidade, porém aumentaria os custos da infraestrutura.

Dessa forma, o projeto mantém:

* Duas Availability Zones;
* Duas subnets privadas;
* Um único NAT Gateway;
* Menor custo de infraestrutura;
* Acesso de saída para os recursos privados.

A utilização de um único NAT Gateway representa uma **limitação conhecida de alta disponibilidade**, pois ele constitui um ponto único de dependência para a conectividade de saída.

Essa decisão está documentada no ADR relacionado à arquitetura de rede.

---

# Kubernetes

O cluster Kubernetes é provisionado utilizando o **Amazon EKS**.

A aplicação é executada através de recursos Kubernetes.

Todos os recursos da aplicação são isolados no namespace:

```text
oficina
```

Os principais recursos Kubernetes utilizados são:

* Namespace;
* Deployment;
* Service;
* Horizontal Pod Autoscaler;
* Migration Job;
* ConfigMap;
* Secret.

---

# Deployment

A aplicação é executada através de um Kubernetes Deployment.

Características:

* 2 réplicas iniciais;
* Estratégia `RollingUpdate`;
* Health Checks;
* CPU e memória configuradas através de requests e limits;
* Configuração através de ConfigMap;
* Informações sensíveis através de Secret;
* Imagem armazenada no Amazon ECR.

## Estratégia de atualização

A estratégia utilizada é:

```text
maxSurge: 1
maxUnavailable: 0
```

Essa configuração permite realizar atualizações gradualmente, mantendo as réplicas disponíveis durante o processo de atualização.

Fluxo simplificado:

```text
Pods antigos
     │
     ▼
Novo Pod criado
     │
     ▼
Novo Pod fica Ready
     │
     ▼
Pod antigo removido
     │
     ▼
Próximo Pod atualizado
```

---

# Health Checks

A aplicação possui três tipos de probes do Kubernetes.

## Startup Probe

Verifica se a aplicação terminou sua inicialização.

Endpoint:

```text
/health/live/
```

A Startup Probe evita que o Kubernetes considere o container como falho enquanto a aplicação ainda está iniciando.

## Liveness Probe

Verifica se a aplicação continua funcionando corretamente.

Endpoint:

```text
/health/live/
```

Caso a aplicação falhe continuamente, o Kubernetes poderá reiniciar o container.

## Readiness Probe

Verifica se a aplicação está pronta para receber requisições.

Endpoint:

```text
/health/ready/
```

Pods que não estiverem prontos não devem receber tráfego do Kubernetes Service.

O endpoint de readiness também é utilizado pelo Target Group do ALB para verificar a saúde da aplicação.

---

# Horizontal Pod Autoscaler

A aplicação utiliza **Horizontal Pod Autoscaler (HPA)** para realizar escalabilidade horizontal dos Pods.

Configuração atual:

| Configuração    | Valor |
| --------------- | ----: |
| Mínimo de Pods  |     2 |
| Máximo de Pods  |     6 |
| Métrica         |   CPU |
| Utilização alvo |   50% |

O HPA utiliza as métricas fornecidas pelo **Kubernetes Metrics Server**.

Quando a utilização média de CPU aumenta, o HPA pode aumentar a quantidade de Pods.

```text
CPU aumenta
     │
     ▼
Horizontal Pod Autoscaler
     │
     ▼
Mais Pods
```

Durante períodos de menor utilização:

```text
CPU diminui
     │
     ▼
Horizontal Pod Autoscaler
     │
     ▼
Menos Pods
```

O número de réplicas permanece entre 2 e 6 Pods.

---

# Migration Job

As migrations do banco de dados são executadas através de um Kubernetes Job.

O Job utiliza a mesma imagem da aplicação e executa:

```bash
python manage.py migrate --noinput
```

Características:

* `restartPolicy: Never`;
* `backoffLimit: 3`;
* Até três tentativas em caso de falha;
* Remoção automática após a conclusão através de TTL.

Fluxo:

```text
Deploy
   │
   ▼
Migration Job
   │
   ▼
Django migrate
   │
   ▼
Amazon RDS
```

A execução das migrations é realizada de forma separada do Deployment da aplicação.

---

# Kubernetes Service

A aplicação é exposta internamente através de um Kubernetes Service do tipo **NodePort**.

Configuração atual:

```text
Port:       8000
TargetPort: 8000
NodePort:   30080
```

O fluxo de comunicação é:

```text
Internal ALB :8000
       │
       ▼
Target Group :30080
       │
       ▼
EKS NodePort :30080
       │
       ▼
Kubernetes Service :8000
       │
       ▼
Django Pod :8000
```

O Service distribui o tráfego entre os Pods disponíveis.

---

# Application Load Balancer

A infraestrutura utiliza um **Application Load Balancer interno**.

Características:

* Tipo: Application Load Balancer;
* Acesso: interno;
* Listener: HTTP;
* Porta do listener: `8000`;
* Target Group: nodes do EKS;
* Porta do Target Group: `30080`;
* Health Check: `/health/ready/`.

O ALB não é exposto diretamente à internet.

O tráfego externo chega ao API Gateway e é encaminhado ao ALB através de VPC Link.

Fluxo:

```text
Cliente
   │
   │ HTTPS
   ▼
API Gateway
   │
   │ VPC Link
   ▼
Internal ALB :8000
   │
   ▼
Target Group :30080
   │
   ▼
EKS Nodes
   │
   ▼
Kubernetes Service
   │
   ▼
Django Pods
```

O ALB é provisionado diretamente pelo Terraform.

A arquitetura não utiliza Kubernetes Ingress ou AWS Load Balancer Controller.

---

# Amazon ECR

O Amazon Elastic Container Registry (ECR) é utilizado para armazenar as imagens Docker da aplicação.

Repositório:

```text
oficina-api
```

O fluxo esperado é:

```text
Código da API
      │
      ▼
CI
      │
      ▼
Testes
      │
      ▼
Docker Build
      │
      ▼
Push para Amazon ECR
      │
      ▼
Atualização da aplicação
      │
      ▼
Deploy no EKS
```

O repositório ECR possui **scan de imagens habilitado no push**.

A imagem armazenada no ECR é utilizada pelo Deployment e pelo Migration Job do Kubernetes.

---

# Configuração e Secrets

As configurações não sensíveis da aplicação são armazenadas através de um Kubernetes ConfigMap.

Exemplos:

```text
DJANGO_DEBUG
DJANGO_SETTINGS_MODULE
DJANGO_ALLOWED_HOSTS
DB_HOST
DB_PORT
STATIC_ROOT
```

Informações sensíveis são armazenadas utilizando Kubernetes Secrets.

Exemplos:

```text
DJANGO_SECRET_KEY
POSTGRES_DB
POSTGRES_USER
POSTGRES_PASSWORD
```

Os valores reais dos Secrets **não devem ser versionados no repositório**.

O repositório disponibiliza apenas arquivos de exemplo para auxiliar na configuração do ambiente.

---

# Segurança

A comunicação entre os componentes é controlada através de **Security Groups**.

Os principais fluxos são:

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

O ALB e os nodes do EKS permanecem em ambiente privado.

As regras de Security Group permitem somente as portas necessárias para a comunicação entre os componentes.

Também é permitida saída HTTPS pela porta `443` para serviços externos necessários à aplicação e à observabilidade.

```text
EKS
 │
 │ HTTPS :443
 ▼
Serviços externos
```

As credenciais da aplicação e do banco de dados não devem ser armazenadas diretamente no código-fonte.

---

# Amazon RDS

O banco de dados PostgreSQL é executado utilizando **Amazon RDS**.

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

A comunicação entre a aplicação e o banco ocorre através da rede privada da VPC.

O acesso ao banco é controlado através de Security Groups.

A infraestrutura do RDS é mantida no repositório específico de banco de dados do projeto.

---

# Estrutura do repositório

```text
tech-challenge-oficina-k8s/
│
├── terraform/
│   │
│   ├── alb.tf
│   ├── ecr.tf
│   ├── eks.tf
│   ├── network.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── security_groups.tf
│   ├── variables.tf
│   ├── versions.tf
│   │
│   └── terraform.tfvars.example
│
├── k8s/
│   │
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   ├── migration-job.yaml
│   └── secret.example.yaml
│
├── docs/
│   ├── adrs/
│   └── architecture.md
│
├── .gitignore
└── README.md
```

> A estrutura pode evoluir conforme novas necessidades do projeto.

---

# Pré-requisitos

Antes de provisionar a infraestrutura, é necessário possuir:

* Terraform `>= 1.5.0`;
* AWS CLI;
* Conta AWS configurada;
* Credenciais AWS válidas;
* kubectl;
* Docker.

Verifique as ferramentas:

```bash
terraform --version
```

```bash
aws --version
```

```bash
kubectl version --client
```

```bash
docker --version
```

---

# Configuração do Terraform

Entre no diretório:

```bash
cd terraform
```

Crie o arquivo:

```text
terraform.tfvars
```

utilizando como referência:

```text
terraform.tfvars.example
```

Exemplo:

```hcl
aws_region = "us-east-1"

eks_cluster_role_arn = "ARN_DA_LAB_EKS_CLUSTER_ROLE"

eks_node_role_arn = "ARN_DA_LAB_EKS_NODE_ROLE"
```

Os valores das roles devem ser obtidos de acordo com as permissões disponibilizadas pelo ambiente AWS Academy.

---

# Provisionando a infraestrutura

Inicialize o Terraform:

```bash
terraform init
```

Valide os arquivos:

```bash
terraform validate
```

Visualize o plano de execução:

```bash
terraform plan
```

Crie a infraestrutura:

```bash
terraform apply
```

---

# Outputs

Após o provisionamento, o Terraform disponibiliza informações importantes através dos outputs.

Para visualizar os outputs:

```bash
terraform output
```

Principais outputs:

* `vpc_id`;
* `public_subnet_ids`;
* `private_subnet_ids`;
* `alb_security_group_id`;
* `alb_listener_arn`;
* `alb_arn`;
* `alb_dns_name`;
* `alb_target_group_arn`;
* `ecr_repository_url`;
* `eks_cluster_security_group_id`.

---

# Configurando o kubectl

Após a criação do cluster EKS:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name oficina-eks
```

Verifique o acesso ao cluster:

```bash
kubectl get nodes
```

---

# Deploy dos manifests Kubernetes

Entre no diretório:

```bash
cd k8s
```

Aplique o namespace:

```bash
kubectl apply -f namespace.yaml
```

Aplique as configurações:

```bash
kubectl apply -f configmap.yaml
```

Configure os Secrets antes de criar o Deployment.

Depois aplique:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
```

Execute as migrations:

```bash
kubectl apply -f migration-job.yaml
```

---

# Verificando o ambiente

Verifique os Pods:

```bash
kubectl get pods -n oficina
```

Verifique os Services:

```bash
kubectl get services -n oficina
```

Verifique o Deployment:

```bash
kubectl get deployment -n oficina
```

Verifique o HPA:

```bash
kubectl get hpa -n oficina
```

Verifique o Job de migration:

```bash
kubectl get jobs -n oficina
```

Verifique os logs de um Pod:

```bash
kubectl logs -n oficina <pod-name>
```

Verifique as métricas:

```bash
kubectl top nodes
```

```bash
kubectl top pods -n oficina
```

---

# Observabilidade

A infraestrutura foi preparada para integração com a solução de monitoramento e observabilidade do projeto.

Os principais indicadores contemplados incluem:

* Utilização de CPU;
* Utilização de memória;
* Número de Pods;
* Escalabilidade do HPA;
* Latência da aplicação;
* Disponibilidade;
* Health Checks;
* Logs da aplicação.

O **Kubernetes Metrics Server** fornece as métricas de CPU e memória utilizadas pelo HPA.

A solução de observabilidade utilizada pelo projeto está integrada ao repositório da aplicação (`tech-challenge-oficina`), sendo responsável pelo monitoramento da aplicação, logs, métricas, dashboards e alertas.

---

# CI/CD

A responsabilidade pelo pipeline de CI/CD está no repositório da aplicação.

O fluxo esperado é:

```text
Push no repositório da API
          │
          ▼
        Testes
          │
          ▼
      Docker Build
          │
          ▼
      Push para ECR
          │
          ▼
 Atualização da imagem
          │
          ▼
       Deploy EKS
          │
          ▼
    Rolling Update
```

O repositório da aplicação é responsável por:

* Execução dos testes;
* Build da imagem Docker;
* Autenticação no Amazon ECR;
* Push da imagem;
* Atualização da versão da imagem utilizada pelo Kubernetes.

Este repositório é responsável por disponibilizar a infraestrutura AWS e Kubernetes necessária para suportar esse fluxo.

---

# Documentação de decisões

As decisões arquiteturais são documentadas através de **ADRs (Architecture Decision Records)**.

Local:

```text
docs/adrs/
```

Entre as decisões documentadas estão:

* Utilização do Amazon EKS;
* Utilização do Amazon ECR;
* Arquitetura de rede;
* Utilização de Application Load Balancer;
* Estratégia de escalabilidade;
* Utilização de Terraform;
* Gerenciamento dos Security Groups do EKS;
* Limitações do ambiente AWS Academy;
* Utilização de um único NAT Gateway;

---

# Repositórios relacionados

O projeto Tech Challenge é dividido em múltiplos repositórios, de acordo com as responsabilidades de cada componente.

| Repositório                       | Responsabilidade                                   | Link |
| --------------------------------- | -------------------------------------------------- | ---- |
| `tech-challenge-oficina`          | Aplicação Backend, Docker, CI/CD e observabilidade | [GitHub](https://github.com/helyomendesdev/tech-challenge-oficina) |
| `tech-challenge-oficina-k8s`      | VPC, EKS, ECR, ALB, Terraform e Kubernetes         | [Este repositório](https://github.com/sophiasussa/tech-challenge-oficina-k8s) |
| `tech-challenge-oficina-database` | RDS PostgreSQL e configuração do banco             | [GitHub](https://github.com/helyomendesdev/tech-challenge-oficina-database) |
| `tech-challenge-oficina-auth`     | API Gateway, Lambda e autenticação                 | [GitHub](https://github.com/helyomendesdev/tech-challenge-oficina-auth) |

---

# Destruição da infraestrutura

Para remover os recursos provisionados pelo Terraform:

```bash
terraform destroy
```

**Atenção:** esse comando remove os recursos gerenciados pelo Terraform.

Antes de executar, confirme se nenhum recurso externo possui dependências associadas à infraestrutura.

Recursos gerenciados por outros repositórios ou criados fora do Terraform deste projeto podem possuir dependências que precisam ser removidas ou tratadas separadamente.

---

# Tecnologias

* AWS;
* Terraform;
* Kubernetes;
* Amazon EKS;
* Amazon ECR;
* Amazon VPC;
* Application Load Balancer;
* Amazon RDS PostgreSQL;
* Amazon API Gateway;
* AWS Lambda;
* Docker;
* Django;
* Kubernetes Metrics Server.

---

Desenvolvido como parte do **Tech Challenge — FIAP**.
