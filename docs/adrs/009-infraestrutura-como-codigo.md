# ADR-009: Provisionamento da infraestrutura utilizando Terraform

## Status

Aceito

## Contexto

A infraestrutura da aplicação possui diversos recursos na AWS.

Entre eles:

- VPC;
- Subnets;
- Internet Gateway;
- NAT Gateway;
- Elastic IP;
- Route Tables;
- Security Groups;
- EKS;
- Managed Node Group;
- ECR;
- Application Load Balancer;
- Target Group;
- Listener.

Criar esses recursos manualmente aumentaria a possibilidade de configurações inconsistentes entre ambientes.

## Decisão

A infraestrutura será definida utilizando Terraform.

Os arquivos Terraform serão responsáveis pelo provisionamento dos recursos AWS utilizados pelo ambiente Kubernetes.

O Terraform também será utilizado para:

- criar recursos;
- atualizar infraestrutura;
- visualizar alterações através do `terraform plan`;
- destruir ambientes quando necessário.

## Consequências

### Positivas

- A infraestrutura fica versionada.
- O ambiente pode ser reproduzido.
- Alterações podem ser revisadas.
- Reduz configurações manuais.
- Facilita a documentação da infraestrutura.

### Negativas

- É necessário gerenciar o Terraform State.
- Alterações incorretas podem afetar recursos existentes.
- A destruição de recursos possui dependências que precisam ser consideradas.
- Alguns recursos podem permanecer temporariamente durante processos de destroy.

## Alternativas consideradas

### Provisionamento manual pelo AWS Console

Não foi escolhido porque não permite reproduzir facilmente a infraestrutura.

### Scripts AWS CLI

Não foi escolhido porque o Terraform fornece gerenciamento declarativo e controle de estado.
