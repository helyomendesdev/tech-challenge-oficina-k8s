# ADR-004: Exposição da aplicação utilizando ALB interno e Kubernetes NodePort

## Status

Aceito

## Contexto

A aplicação executada no Kubernetes precisa ser acessível por outros componentes da arquitetura.

Foi necessário definir uma estratégia para encaminhar requisições HTTP até os Pods da aplicação.

A infraestrutura possui um Application Load Balancer provisionado pelo Terraform.

O Kubernetes Service precisa fornecer um ponto de acesso estável para os Pods da aplicação.

## Decisão

Foi adotada a seguinte arquitetura:

Cliente interno
      ↓
Application Load Balancer
      ↓
Target Group
      ↓
NodePort
      ↓
Kubernetes Service
      ↓
Pods da aplicação

Foi criado um Application Load Balancer interno.

### O ALB possui:

tipo application;
protocolo HTTP;
listener na porta 8000;
execução nas subnets privadas.

### O Target Group utiliza:

protocolo HTTP;
porta 30080;
target type instance.

### O Kubernetes Service utiliza:

type: NodePort

com:

port: 8000
targetPort: 8000
nodePort: 30080

### O ALB realiza health checks utilizando:

/health/ready/

## Consequências

### Positivas

-O tráfego é distribuído pelo Application Load Balancer.
-O Kubernetes Service fornece acesso aos Pods.
-Os Pods podem ser substituídos sem alterar o ponto de acesso do Service.
-O ALB possui health checks independentes.
-A aplicação possui um caminho definido entre a infraestrutura AWS e os Pods.

### Negativas

-A arquitetura depende de uma porta NodePort fixa.
-Existe maior acoplamento entre o ALB e a configuração do Kubernetes Service.
-Regras de Security Groups precisam ser configuradas corretamente.
-A configuração é mais complexa do que uma exposição simples utilizando LoadBalancer.

## Alternativas consideradas

### Service do tipo LoadBalancer

Não foi escolhido nesta implementação porque a infraestrutura utiliza um ALB provisionado diretamente pelo Terraform.

### ClusterIP

Não foi escolhido isoladamente porque o ClusterIP não fornece acesso direto para o Target Group configurado no ALB.

### Ingress Controller

Pode ser considerado futuramente caso seja necessário um gerenciamento mais avançado de roteamento HTTP dentro do cluster.
