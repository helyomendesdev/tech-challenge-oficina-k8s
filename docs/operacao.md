# Operação — Terraform e verificação detalhada

## Configuração do Terraform

Variáveis (`terraform/variables.tf`):

| Variável | Obrigatória | Default | Origem no CI |
| --- | --- | --- | --- |
| `aws_region` | não | `us-east-1` | `environments/<ambiente>/terraform.tfvars` |
| `eks_cluster_role_arn` | sim | — | secret `EKS_CLUSTER_ROLE_ARN` do GitHub Environment |
| `eks_node_role_arn` | sim | — | secret `EKS_NODE_ROLE_ARN` do GitHub Environment |

Para uso local, copie `terraform/terraform.tfvars.example` para `terraform/terraform.tfvars` e preencha as duas roles com os ARNs disponibilizados pelo laboratório AWS Academy. Os arquivos `terraform/environments/{homologacao,producao}/terraform.tfvars` são os usados pelo pipeline (`cd.yml`), que injeta as roles via `-var` a partir dos Secrets do ambiente (`homologacao` na branch `develop`, `producao` na branch `main`).

Backend remoto: S3 + lock em DynamoDB, configurado via `-backend-config` no CI (bucket, `key=k8s/<branch>/terraform.tfstate`, region e tabela de lock) — a declaração `backend "s3" {}` em `versions.tf` fica parcial de propósito, e cada branch usa seu próprio workspace Terraform.

## Recursos gerenciados

VPC, subnets públicas e privadas, Internet Gateway, NAT Gateway, Route Tables, Security Groups, Amazon ECR, Amazon EKS + Managed Node Group, Application Load Balancer, Target Group e Listener.

### Node Group (EKS)

`terraform/node_group.tf`: instância `t3.small`, `desired_size: 2`, `min_size: 2`, `max_size: 4`, anexado ao Target Group do ALB via `aws_autoscaling_attachment`.

## Outputs (`terraform/outputs.tf`)

`vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `alb_security_group_id`, `alb_listener_arn`, `alb_arn`, `alb_dns_name`, `alb_target_group_arn`, `ecr_repository_url`, `eks_cluster_security_group_id` (este último é o que o repositório de banco de dados usa para autorizar a porta 5432 no RDS).

```bash
terraform output
```

## Verificação detalhada

```bash
kubectl get pods -n oficina
kubectl get services -n oficina
kubectl get deployment -n oficina
kubectl get hpa -n oficina
kubectl get jobs -n oficina
kubectl logs -n oficina <pod-name>
kubectl top nodes
kubectl top pods -n oficina
```
