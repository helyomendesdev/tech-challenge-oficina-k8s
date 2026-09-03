# ADR-003: Utilização do Amazon ECR para armazenamento das imagens da aplicação

## Status

Aceito

## Contexto

A aplicação é distribuída como uma imagem Docker.

O ambiente Kubernetes precisa acessar uma imagem centralizada e disponível dentro da infraestrutura AWS.

Também é necessário integrar o processo de CI/CD com o armazenamento das imagens.

## Decisão

Foi criado um repositório no Amazon Elastic Container Registry (ECR).

O repositório utilizado será:

`oficina-api`

A imagem da aplicação será construída pelo processo de CI/CD e enviada para o ECR.

O ECR será utilizado como registro oficial das imagens da aplicação.

A configuração de scan automático foi habilitada:

scan_on_push = true

### O fluxo de publicação será:

Testes
   ↓
Build da imagem Docker
   ↓
Push para o Amazon ECR
   ↓
Atualização da imagem utilizada pelo Kubernetes

## Decisão Consequências

### Positivas

-Integração nativa com a AWS.
-Centralização das imagens da aplicação.
-Integração com o processo de CI/CD.
-Possibilidade de escaneamento de imagens.
-O ambiente Kubernetes pode utilizar uma imagem armazenada em um registry centralizado.

### Negativas

-Exige autenticação para envio e acesso às imagens.
-As imagens armazenadas precisam ser gerenciadas.
-O processo de destroy precisa considerar imagens existentes no repositório.

## Alternativas consideradas

### Docker Hub

Não foi escolhido como registry principal porque o projeto utiliza infraestrutura AWS.

### Registry local

Não foi escolhido porque não seria adequado para o ambiente distribuído em AWS.
