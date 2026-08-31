# Tech Challenge Oficina — Infraestrutura Kubernetes

Infraestrutura como código do cluster Kubernetes da Fase 3 do Tech Challenge FIAP.

## Responsabilidade

- Provisionar o cluster Kubernetes com Terraform.
- Configurar rede, acesso, escalabilidade e HPA.
- Preparar ambientes de homologação e produção.
- Expor outputs necessários para o deploy da aplicação.
- Integrar métricas, logs e healthchecks com a solução de observabilidade.

Responsável técnica: Sophia Sussa Campos Bastos (`sophiasussa`).

## Decisões pendentes

Devem ser registradas em RFC/ADR antes da implementação definitiva:

- Provedor de nuvem.
- Serviço Kubernetes gerenciado.
- Estratégia de rede e acesso ao banco.
- Estado remoto do Terraform.
- Local dos módulos do API Gateway.
- Integração com autenticação serverless e observabilidade.

## Estrutura planejada

```text
terraform/
  modules/
  environments/
    homologacao/
    producao/
docs/
  adrs/
  rfcs/
```

A estrutura será implementada após validação com a responsável pela infraestrutura.

## Branches e ambientes

- `develop`: homologação.
- `main`: produção.
- Mudanças entram exclusivamente por Pull Request.

## Status

Estrutura inicial criada. Terraform e CI/CD serão adicionados após a escolha da nuvem.
