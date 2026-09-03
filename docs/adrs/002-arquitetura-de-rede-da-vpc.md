# ADR-002: Arquitetura de rede utilizando VPC com subnets públicas e privadas

## Status

Aceito

## Contexto

A infraestrutura precisa fornecer isolamento de rede para os recursos da aplicação.

O cluster Kubernetes e seus nodes não devem ser expostos diretamente à Internet.

Ao mesmo tempo, os recursos localizados nas subnets privadas precisam possuir acesso de saída para serviços externos.

Além disso, a infraestrutura deve estar distribuída em mais de uma Availability Zone para melhorar a disponibilidade.

## Decisão

Foi criada uma VPC dedicada para a aplicação.

A VPC utiliza o bloco CIDR:

`10.0.0.0/16`

A arquitetura possui quatro subnets:

### Subnets públicas

- `10.0.1.0/24`
- `10.0.2.0/24`

As subnets públicas são utilizadas para recursos que precisam de conectividade com a Internet.

### Subnets privadas

- `10.0.11.0/24`
- `10.0.12.0/24`

As subnets privadas são utilizadas pelo cluster EKS e pelos nodes da aplicação.

As subnets estão distribuídas em duas Availability Zones.

Foi configurado:

- Internet Gateway;
- NAT Gateway;
- Elastic IP;
- tabela de rotas pública;
- tabela de rotas privada.

O NAT Gateway é utilizado para permitir que recursos das subnets privadas realizem conexões de saída sem receber acesso direto da Internet.

## Consequências

### Positivas

- Os nodes da aplicação permanecem em subnets privadas.
- A arquitetura possui distribuição entre duas Availability Zones.
- Os recursos privados possuem acesso de saída por meio do NAT Gateway.
- A infraestrutura possui maior isolamento de rede.

### Negativas

- O NAT Gateway possui custo.
- Existe maior complexidade na configuração de rotas.
- A destruição da infraestrutura pode levar mais tempo.

## Alternativas consideradas

### Executar todos os recursos em subnets públicas

Não foi escolhido porque aumentaria a exposição dos recursos da aplicação.

### Utilizar apenas uma subnet

Não foi escolhido porque reduziria a disponibilidade e não permitiria distribuição entre Availability Zones.
