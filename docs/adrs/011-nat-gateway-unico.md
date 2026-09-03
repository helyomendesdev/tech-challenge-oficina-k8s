# ADR-011: Utilização de um único NAT Gateway devido às restrições do AWS Academy

## Status

Aceito

## Contexto

A infraestrutura utiliza subnets privadas para os recursos do Amazon EKS.

Os recursos localizados nessas subnets precisam de acesso de saída à internet para determinadas operações, como:

* Download e atualização de dependências;
* Comunicação com serviços externos;
* Comunicação com ferramentas de observabilidade;
* Acesso a serviços da AWS que não possuem conectividade privada configurada.

Para permitir esse acesso sem expor diretamente os recursos das subnets privadas à internet, foi utilizado um NAT Gateway.

A infraestrutura foi planejada com duas Availability Zones, contendo:

* Duas subnets públicas;
* Duas subnets privadas;
* Um NAT Gateway;
* Um Internet Gateway.

A arquitetura implementada é:

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
                  ┌─────────┴─────────┐
                  │                   │
                  ▼                   ▼
           Private Subnet A    Private Subnet B
                  │                   │
                  └─────────┬─────────┘
                            │
                            ▼
                           EKS
```

## Restrição do ambiente

O projeto é desenvolvido utilizando o **AWS Academy**, que possui limitações de recursos e de orçamento em comparação com uma conta AWS convencional.

Nesse contexto, a infraestrutura precisa considerar não apenas as boas práticas de arquitetura, mas também:

* Limite de créditos disponíveis;
* Custos dos recursos provisionados;
* Restrições de serviços e permissões;
* Necessidade de manter a infraestrutura compatível com o ambiente acadêmico.

O NAT Gateway possui custo associado ao seu provisionamento e utilização. Dessa forma, utilizar um NAT Gateway em cada Availability Zone aumentaria o custo da infraestrutura.

Considerando o orçamento limitado do AWS Academy, a utilização de dois NAT Gateways foi considerada inadequada para o contexto atual do projeto.

## Decisão

Será utilizado **um único NAT Gateway**, localizado na subnet pública da primeira Availability Zone.

As duas subnets privadas utilizarão esse NAT Gateway para acesso externo.

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
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
   Private Subnet A      Private Subnet B
          │                     │
          └──────────┬──────────┘
                     ▼
                    EKS
```

## Justificativa

A decisão foi tomada principalmente considerando as limitações do AWS Academy.

A utilização de um único NAT Gateway:

* Reduz o custo da infraestrutura;
* Permite permanecer dentro do orçamento disponível;
* Atende às necessidades do ambiente acadêmico;
* Mantém as workloads do EKS em subnets privadas;
* Permite acesso de saída à internet sem expor diretamente os nodes do EKS.

Portanto, embora não seja a arquitetura de maior disponibilidade, ela representa um equilíbrio adequado entre **custo, disponibilidade, segurança e requisitos do projeto** dentro do ambiente AWS Academy.

## Consequências

A principal consequência é uma limitação de alta disponibilidade.

As duas Availability Zones possuem subnets privadas, porém ambas dependem do mesmo NAT Gateway para acesso externo.

Dessa forma, o NAT Gateway representa um ponto único de dependência para a conectividade de saída.

Caso ocorra uma indisponibilidade na Availability Zone onde o NAT Gateway está localizado, os recursos da outra Availability Zone poderão perder o acesso de saída à internet e a serviços externos que dependam dessa conectividade.

Isso significa que a infraestrutura possui redundância entre Availability Zones para os recursos do EKS, mas **não possui alta disponibilidade completa para o caminho de saída através do NAT Gateway**.

## Limitação conhecida

A arquitetura atual não utiliza um NAT Gateway por Availability Zone.

Uma arquitetura mais adequada para um ambiente de produção poderia utilizar um NAT Gateway dedicado para cada Availability Zone:

```text
             Public Subnet A          Public Subnet B
                    │                       │
                    ▼                       ▼
             NAT Gateway A           NAT Gateway B
                    │                       │
                    ▼                       ▼
            Private Subnet A         Private Subnet B
                    │                       │
                    └──────────┬────────────┘
                               ▼
                              EKS
```

Nesse modelo:

* Cada Availability Zone possui seu próprio NAT Gateway;
* Cada subnet privada utiliza o NAT Gateway da mesma Availability Zone;
* A dependência de uma única Availability Zone é reduzida;
* A disponibilidade do acesso de saída é maior.

Entretanto, essa arquitetura também aumenta o custo da infraestrutura.

## Alternativas consideradas

### Um NAT Gateway

**Vantagens:**

* Menor custo;
* Menor quantidade de recursos;
* Menor complexidade;
* Compatível com o orçamento do AWS Academy;
* Atende às necessidades do projeto acadêmico.

**Desvantagens:**

* Não oferece alta disponibilidade completa;
* Cria um ponto único de dependência para acesso de saída;
* Pode afetar as duas Availability Zones caso o NAT Gateway fique indisponível.

### Um NAT Gateway por Availability Zone

**Vantagens:**

* Maior disponibilidade;
* Redução da dependência de uma única Availability Zone;
* Arquitetura mais adequada para ambientes de produção.

**Desvantagens:**

* Maior custo;
* Maior quantidade de recursos;
* Maior complexidade operacional;
* Maior consumo do orçamento disponível no AWS Academy.

## Decisão final

Será utilizado **um único NAT Gateway** no ambiente atual do Tech Challenge.

Essa decisão é considerada adequada devido às restrições de custo e recursos do **AWS Academy**, mantendo os recursos do EKS em subnets privadas e permitindo a conectividade de saída necessária para o funcionamento da infraestrutura.

A ausência de um NAT Gateway por Availability Zone é considerada uma **limitação conhecida de alta disponibilidade**, e não um erro de implementação.

Caso o projeto seja posteriormente executado em uma conta AWS com orçamento e requisitos de produção, a arquitetura poderá ser revisada para utilizar um NAT Gateway por Availability Zone.
