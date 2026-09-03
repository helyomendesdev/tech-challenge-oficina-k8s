# ADR-010: Gerenciamento dos Security Groups criados automaticamente pelo Amazon EKS

## Status

Aceito

## Contexto

A infraestrutura utiliza o Amazon EKS para o provisionamento e gerenciamento do cluster Kubernetes.

Durante a criação do cluster, o Amazon EKS cria automaticamente um Security Group associado ao cluster, denominado **Cluster Security Group**.

Esse Security Group é utilizado pelo EKS para controlar a comunicação entre componentes do cluster e recursos associados.

A infraestrutura também utiliza um Application Load Balancer interno, que encaminha requisições para a aplicação Kubernetes através de um NodePort.

Para permitir essa comunicação, foi criada uma regra permitindo o tráfego do ALB para a porta `30080`.

A regra utiliza como destino o Security Group criado automaticamente pelo EKS:

```text
ALB
 │
 │ Porta 30080
 ▼
EKS Cluster Security Group
 │
 ▼
Nodes
 │
 ▼
Kubernetes Service
 │
 ▼
Pods
```

## Decisão

Será utilizado o Cluster Security Group criado automaticamente pelo Amazon EKS para configurar regras de comunicação necessárias entre o Application Load Balancer e os recursos do cluster.

A regra de entrada permite:

* Origem: Security Group do ALB;
* Destino: Cluster Security Group do EKS;
* Protocolo: TCP;
* Porta: `30080`.

A referência ao Security Group é obtida através da configuração do cluster:

```hcl
aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
```

## Consequências

A utilização do Security Group criado automaticamente pelo EKS introduz uma dependência entre recursos gerenciados pelo Terraform e recursos criados automaticamente pela AWS.

Durante a destruição da infraestrutura, foi identificado que regras de Security Groups associadas ao Cluster Security Group do EKS podem continuar existindo após a remoção do cluster.

Isso pode impedir a exclusão de outros Security Groups e da VPC.

O problema ocorreu porque uma regra de entrada no Security Group criado pelo EKS ainda referenciava o Security Group do ALB.

A sequência de dependência era:

```text
Cluster Security Group do EKS
        │
        │ Regra de entrada
        ▼
Security Group do ALB
        │
        ▼
VPC
```

Enquanto essa referência existisse, a AWS não permitia a exclusão do Security Group do ALB.

Como consequência, o Terraform apresentava o erro:

```text
DependencyViolation:
resource has a dependent object
```

A remoção da dependência exigiu a identificação da regra associada ao Security Group do EKS e sua exclusão.

## Consequências conhecidas

Durante operações de `terraform destroy`, recursos criados automaticamente pelo Amazon EKS podem manter dependências que não são removidas automaticamente na ordem esperada pelo Terraform.

Nessas situações, pode ser necessário investigar manualmente:

* Security Groups;
* Regras de Security Groups;
* Referências entre Security Groups;
* Network Interfaces;
* Recursos criados automaticamente pelo EKS.

A remoção manual de uma regra dependente pode ser necessária antes da destruição completa da infraestrutura.

## Alternativas consideradas

### Gerenciar exclusivamente Security Groups criados pelo Terraform

Essa alternativa permitiria maior controle sobre o ciclo de vida dos recursos.

Entretanto, o Amazon EKS cria e utiliza um Cluster Security Group automaticamente, sendo necessário considerar sua existência na configuração da infraestrutura.

### Utilizar o Cluster Security Group criado pelo EKS

Essa alternativa foi escolhida porque permite configurar a comunicação necessária com os recursos do cluster utilizando o Security Group efetivamente associado ao EKS.

## Decisão final

O projeto utilizará o Cluster Security Group criado automaticamente pelo Amazon EKS para as regras necessárias de comunicação com o cluster.

As dependências criadas entre Security Groups devem ser consideradas durante operações de destruição da infraestrutura.
