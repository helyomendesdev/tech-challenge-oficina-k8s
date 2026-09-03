# Architecture Decision Records

Esta pasta contém os Architecture Decision Records (ADRs) relacionados ao repositório `tech-challenge-oficina-k8s`.

Os ADRs documentam decisões arquiteturais importantes relacionadas à infraestrutura e à execução da aplicação.

## ADRs

| ADR | Decisão |
|---|---|
| ADR-001 | Utilização do Amazon EKS |
| ADR-002 | Arquitetura de rede utilizando VPC |
| ADR-003 | Utilização do Amazon ECR |
| ADR-004 | Exposição da aplicação utilizando ALB e NodePort |
| ADR-005 | Escalabilidade horizontal utilizando HPA |
| ADR-006 | Disponibilidade e atualização utilizando Rolling Update e Health Checks |
| ADR-007 | Gerenciamento de configurações e informações sensíveis |
| ADR-008 | Execução das migrations utilizando Kubernetes Job |
| ADR-009 | Infraestrutura como código utilizando Terraform |
| ADR-010 | Gerenciamento dos Security Groups criados automaticamente pelo Amazon EKS |
| ADR-011 | Utilização de um único NAT Gateway devido às restrições do AWS Academy |
