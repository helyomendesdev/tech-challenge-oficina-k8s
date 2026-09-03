# ADR-001: Utilização do Amazon EKS para orquestração da aplicação

## Status

Aceito

## Contexto

A aplicação da oficina é uma API baseada em Django que precisa ser executada em uma infraestrutura escalável e preparada para alta disponibilidade.

O ambiente anterior utilizava containers executados localmente, incluindo testes e deploy utilizando Kind. Entretanto, essa abordagem não representa a arquitetura de produção definida para o projeto.

Foi necessário definir uma plataforma de orquestração de containers capaz de:

- executar múltiplas réplicas da aplicação;
- realizar atualizações sem indisponibilidade;
- permitir escalabilidade horizontal;
- integrar-se com serviços da AWS;
- executar workloads baseados em containers;
- fornecer mecanismos de health checks e recuperação automática.

## Decisão

Foi adotado o Amazon Elastic Kubernetes Service (EKS) como plataforma de orquestração da aplicação.

O cluster será executado dentro de uma VPC própria, utilizando duas subnets privadas distribuídas em diferentes Availability Zones.

A infraestrutura do EKS será provisionada utilizando Terraform.

O cluster será composto por:

- Amazon EKS;
- Managed Node Group;
- duas instâncias desejadas inicialmente;
- instâncias do tipo `t3.small`;
- capacidade mínima de dois nodes;
- capacidade máxima de quatro nodes.

## Consequências

### Positivas

- Permite execução de múltiplas réplicas da aplicação.
- Permite escalabilidade horizontal utilizando Kubernetes.
- Possui mecanismos de recuperação automática de containers.
- Permite Rolling Updates.
- Integra-se com outros serviços da AWS.
- Facilita a execução de Jobs, Deployments e Services.
- Permite separar a infraestrutura da aplicação.

### Negativas

- Aumenta a complexidade da infraestrutura.
- Exige conhecimento de Kubernetes.
- Possui maior custo operacional quando comparado a uma execução simples com containers.
- O provisionamento e destruição do cluster podem levar vários minutos.

## Alternativas consideradas

### Docker Compose

Não foi escolhido porque não fornece mecanismos nativos de orquestração, escalabilidade horizontal e gerenciamento de múltiplos nodes.

### Kind

O Kind pode continuar sendo utilizado para testes locais ou validações de integração.

Entretanto, não foi escolhido como ambiente principal porque não representa a arquitetura de produção baseada em AWS.

### Amazon ECS

Não foi adotado porque o projeto utiliza Kubernetes como tecnologia de orquestração e possui manifests Kubernetes como parte da infraestrutura.
