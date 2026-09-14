# Rede e segurança — referência de configuração

Valores concretos de rede e segurança provisionados pelo Terraform (`terraform/vpc.tf`, `security_groups.tf`, `alb.tf`, `ecr.tf`). Para o racional das decisões, veja [architecture.md](architecture.md) e os ADRs [002](adrs/002-arquitetura-de-rede-da-vpc.md), [003](adrs/003-uso-do-amazon-ecr.md), [004](adrs/004-exposicao-da-aplicacao-com-alb-e-nodeport.md), [010](adrs/010-gerenciamento-security-groups-eks.md) e [011](adrs/011-nat-gateway-unico.md).

## VPC e subnets

| Recurso | CIDR | Availability Zone |
| --- | --- | --- |
| VPC `oficina-vpc` | `10.0.0.0/16` | — |
| Subnet pública A | `10.0.1.0/24` | AZ 1 |
| Subnet pública B | `10.0.2.0/24` | AZ 2 |
| Subnet privada A | `10.0.11.0/24` | AZ 1 |
| Subnet privada B | `10.0.12.0/24` | AZ 2 |

Rotas: subnets públicas → Internet Gateway (`oficina-igw`); subnets privadas → NAT Gateway único (`oficina-nat`, alocado na subnet pública A).

## Cluster EKS (rede)

Cluster `oficina-eks`, versão `1.35`, com o Managed Node Group nas subnets privadas A/B. Endpoint do cluster com acesso privado e público habilitados (`endpoint_private_access = true`, `endpoint_public_access = true`) e security group próprio (`oficina-eks-sg`).

## NAT Gateway único e AWS Academy

A infraestrutura usa **um único NAT Gateway**, compartilhado pelas duas subnets privadas, por restrição de custo/recursos do ambiente AWS Academy — um NAT Gateway por AZ daria mais disponibilidade, mas custaria mais. É uma limitação conhecida de alta disponibilidade (ponto único de dependência para a saída à internet), documentada em [ADR-011](adrs/011-nat-gateway-unico.md).

## Security Groups

| Regra | Sentido | Porta |
| --- | --- | --- |
| `alb_from_vpc` (ingress no SG do ALB) | VPC (`10.0.0.0/16`) → ALB | TCP `8000` |
| `alb_to_nodes` (egress no SG do ALB) | ALB → security group do cluster EKS | TCP `30080` |
| `nodes_from_alb` (ingress no security group do cluster EKS) | ALB → nodes | TCP `30080` |
| `eks_https` (egress no SG `oficina-eks-sg`) | EKS → `0.0.0.0/0` | TCP `443` (New Relic e demais serviços externos) |

Nota de implementação: um managed node group sem launch template herda o *cluster security group* criado pelo próprio EKS — não o `aws_security_group.eks` — por isso a regra de entrada do NodePort é aplicada nesse security group gerenciado pelo EKS (comentário em `terraform/security_groups.tf`).

## Application Load Balancer

ALB interno (`internal = true`), tipo `application`, nas subnets privadas. Listener HTTP `:8000` encaminha para o Target Group `oficina-eks-tg` (`target_type = instance`, porta `30080`, health check `GET /health/ready/`, intervalo 30s, timeout 5s, 2 checagens para saudável/não saudável). Não usa Kubernetes Ingress nem AWS Load Balancer Controller — decisão registrada no [ADR-004](adrs/004-exposicao-da-aplicacao-com-alb-e-nodeport.md).

## Amazon ECR

Repositório `oficina-api`, com `scan_on_push` habilitado. A imagem é usada tanto pelo Deployment quanto pelo Migration Job do Kubernetes ([ADR-003](adrs/003-uso-do-amazon-ecr.md)).

## Amazon RDS

O PostgreSQL roda em Amazon RDS, fora deste repositório — provisionado em `tech-challenge-oficina-database`. A comunicação EKS → RDS usa a porta `5432` dentro da rede privada da VPC; o output `eks_cluster_security_group_id` deste repositório é o que o RDS deve autorizar nessa porta.
