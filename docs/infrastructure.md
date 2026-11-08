# Infraestrutura compartilhada

Este repositório (`tech-challenge-oficina-k8s`) mantém a infraestrutura comum
do serviço principal/monólito, OS Service, Execution Service e Billing Service.
Há uma VPC, um cluster EKS, um ALB existente e repositórios ECR compartilhados;
os serviços não criam cópias desses recursos.

Na versão do contrato Saga consultada, o orquestrador da Saga reside no OS
Service; não é um quinto workload separado. O serviço principal/monólito
existente permanece como workload distinto no namespace `oficina`.

## Responsabilidades e dependências

| Camada | Responsabilidade |
|---|---|
| `tech-challenge-oficina-k8s` | VPC, subnets, gateways, Security Groups, EKS, Managed Node Group, ALB, ECR, filas SQS da Saga e seus DLQs, namespaces comuns |
| `tech-challenge-oficina-database` | RDS PostgreSQL do OS Service, usando VPC/subnets desta infraestrutura |
| `tech-challenge-oficina-execution` | DynamoDB do Execution Service e seu State independente |
| Repositório Billing | Banco próprio do Billing; tecnologia/infraestrutura ainda a definir |
| Repositórios de aplicação | Lógica, imagens e workloads específicos do componente |

O State de cada repositório é separado. Não consumir o State de outro projeto
com `terraform_remote_state`; compartilhar os IDs/URLs de outputs por variáveis
de ambiente protegidas do pipeline ou por configuração operacional aprovada.
Esses outputs são identificadores, não credenciais.

Os manifests comuns existentes usam o namespace `oficina`; nele ficam o serviço
principal e o OS Service conforme o manifesto atual do OS. Os namespaces
`oficina-execution` e `oficina-billing` são criados para os outros workloads
(o Billing já declara `oficina-billing`). As imagens e workloads permanecem nos
repositórios dos serviços. O ServiceAccount `billing-runtime` é criado porque
o workload Billing existente o referencia, mas não recebe role AWS. O README
do Execution requer um ServiceAccount compartilhado ligado à identidade AWS,
mas não define seu nome; não foi criado um ServiceAccount arbitrário. As
identidades AWS e credenciais das aplicações não são criadas por estes manifests.

## Mensageria SQS

O contrato AsyncAPI v1.1.0 do repositório Saga declara três filas FIFO e três
DLQs. A topologia implementada é:

| Fila | Uso | DLQ |
|---|---|---|
| `oficina-billing-comandos.fifo` | comandos do orquestrador para Billing | `oficina-billing-comandos-dlq.fifo` |
| `oficina-execucao-comandos.fifo` | comandos do orquestrador para Execution | `oficina-execucao-comandos-dlq.fifo` |
| `oficina-os-saga-respostas.fifo` | respostas de Billing e Execution consumidas pelo orquestrador OS | `oficina-os-saga-respostas-dlq.fifo` |

Cada fila principal usa visibilidade de 30 segundos, redrive após cinco
recebimentos, `deduplication_scope = messageGroup` e
`fifo_throughput_limit = perMessageGroupId`. O contrato exige
`MessageGroupId = sagaId` e `MessageDeduplicationId = messageId`; a deduplicação
FIFO de cinco minutos não substitui a idempotência da Inbox. Propague
`traceparent` e `tracestate` como `MessageAttributes`, não no corpo. As DLQs
retêm mensagens por 14 dias. A retenção não definida para as filas principais
mantém o padrão SQS de quatro dias. Todas usam criptografia gerenciada pelo SQS.

O AsyncAPI é a fonte dos nomes e relações acima; não foi criada uma segunda
fila de respostas para Execution ou Billing. As políticas SQS permanecem no
comportamento padrão da conta proprietária (sem acesso cross-account). Antes
de permitir acesso por workload, a equipe deve confirmar os principals/roles
e a política IAM mínima; o Learner Lab pode impedir a criação de roles e
policies. Não coloque access keys em ConfigMaps, Secrets versionados ou
Terraform.

Há uma divergência operacional a resolver antes de ativar os produtores: a
documentação do Execution registra que o publisher atual do OS agrupa por
`os-{osId}`, enquanto o AsyncAPI exige `MessageGroupId = sagaId`. A
infraestrutura segue o contrato normativo e não altera código dos serviços.
O README do Execution também informa que `CancelarExecucao` ainda não é
processado e acaba na DLQ. Validar o alinhamento do publisher/contrato e a
implementação de cancelamento com a equipe antes de declarar a integração pronta.

## Outputs para os outros repositórios

Na pasta `terraform`, `terraform output` disponibiliza:

* `vpc_id`, `vpc_cidr_block`, `public_subnet_ids`, `private_subnet_ids`;
* `eks_cluster_name`, `eks_cluster_endpoint`;
* `ecr_repository_urls` (`api`, `os`, `execution`, `billing`), além do output
  anterior `ecr_repository_url` para compatibilidade;
* `sqs_queue_urls` e `sqs_queue_arns`, indexados pelo nome completo da fila;
* `sqs_dlq_urls` e `sqs_dlq_arns`.

Por exemplo, obtenha os valores durante uma operação autorizada na pasta
`terraform` com `terraform output -raw vpc_id` ou
`terraform output -json private_subnet_ids`. Transfira os valores necessários
para os repositórios/pipelines como parâmetros de configuração, sem compartilhar
arquivos de State. O repositório de banco usa `vpc_id` e subnets privadas; os
serviços recebem apenas as URLs das filas que consomem/publicam e a URL do ECR
correspondente. Não use os outputs para transportar segredos.

## Terraform State remoto e bootstrap

O Terraform principal usa o backend S3 com a chave
`shared/terraform.tfstate` e locking nativo do S3 (`use_lockfile = true`),
disponível desde Terraform 1.10. Versionamento do bucket mantém versões
recuperáveis do State; o lockfile S3 evita operações concorrentes. Requer
permissões no bucket para `ListBucket`, ler/gravar/apagar o objeto da chave do
State e criar/ler/apagar a chave `.tflock` correspondente. Restrinja essas
permissões a integrantes/automação autorizados. O State pode conter dados
sensíveis mesmo quando outputs não os expõem.
O bootstrap expõe `state_access_policy_json`, uma policy de referência limitada
às duas chaves e lockfiles deste repositório. A policy não é anexada a nenhuma
identidade: associe-a somente aos principals aprovados, junto com permissões
bootstrap estritamente necessárias, conforme o controle de acesso disponível.

O bucket é criado separadamente pela configuração
`terraform/backend-bootstrap`, sem backend na primeira execução. Isso evita
uma dependência circular:

1. Configure credenciais temporárias válidas e uma região. O nome S3 deve ser
   globalmente único e estar disponível no AWS Academy.
2. Execute o bootstrap sem backend remoto:

   ```powershell
   terraform -chdir=terraform/backend-bootstrap init -backend=false
   terraform -chdir=terraform/backend-bootstrap plan -var="state_bucket_name=<bucket-globalmente-unico>"
   terraform -chdir=terraform/backend-bootstrap apply -var="state_bucket_name=<bucket-globalmente-unico>"
   ```

   Ele habilita bloqueio de acesso público, versionamento e criptografia AES256.
   O State inicial do bootstrap fica local; proteja-o e não o versione.
3. Migre o State do bootstrap para o bucket criado, mantendo sua chave separada:

   ```powershell
   terraform -chdir=terraform/backend-bootstrap init -migrate-state `
     -backend-config="bucket=<bucket-globalmente-unico>" `
     -backend-config="region=<regiao>" `
     -backend-config="key=bootstrap/terraform.tfstate"
   ```

4. Inicialize a infraestrutura compartilhada, migrando seu State local se ele
   contiver recursos gerenciados. Cada integrante deve usar o mesmo bucket,
   região e chave:

   ```powershell
   terraform -chdir=terraform init -migrate-state `
     -backend-config="bucket=<bucket-globalmente-unico>" `
     -backend-config="region=<regiao>"
   ```

   Se não houver State local a migrar, use `init` sem `-migrate-state`. Não
   copie, commite ou misture o State dos repositórios de serviços.
5. Para uso futuro, os membros executam `terraform init` depois de obter a
   configuração aprovada do backend; operações de plan/apply devem passar pelo
   controle de acesso combinado da equipe.

Se o bucket já existir e contiver State, confirme a propriedade e os objetos
antes de aplicar o bootstrap. Não aplique uma configuração nova sobre um bucket
existente sem revisar o plano. Não destrua o bucket nem remova versões do State
como parte do ciclo normal da infraestrutura.

## AWS Academy e migração para uma conta AWS completa

O Terraform adota credenciais temporárias providas pelo AWS Academy através da
cadeia padrão de credenciais AWS (por exemplo, variáveis de ambiente/profile
temporário do CLI); não define credenciais fixas. Credenciais da sessão expiram
e devem ser renovadas antes de executar Terraform/AWS CLI. Elas não são
automaticamente credenciais dos Pods.

O workflow de CD também precisa de secrets configurados no GitHub para
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`,
`AWS_REGION`, `TF_STATE_BUCKET`, `EKS_CLUSTER_ROLE_ARN` e
`EKS_NODE_ROLE_ARN`. A sessão temporária precisa estar válida durante cada
execução; não cadastre chaves permanentes para contornar sua expiração.

O cluster e o Managed Node Group exigem as roles informadas por
`eks_cluster_role_arn` e `eks_node_role_arn`, além de `iam:PassRole` e permissões
de provisionamento EKS/EC2/VPC. O Terraform atual não cria essas roles, instance
profiles, trust policies ou policies administradas pela AWS. Também não cria
IRSA, EKS Pod Identity ou o AWS Load Balancer Controller. A configuração pode
passar no `validate` e ainda assim falhar em `plan`/`apply` por restrição do
Learner Lab, role indisponível ou limite de serviço. Confirmar com AWS CLI e
tentativa real autorizada; não assumir disponibilidade de EKS, ECR, SQS FIFO,
DLQ, DynamoDB, RDS, ALB ou S3 a partir de validação estática.

O State S3 necessita permissões de bucket e operações de objetos; o backend
nativo necessita locking de objeto. O bucket usa recursos S3 convencionais, mas
o bloqueio de políticas públicas pode impedir policy bucket-level customizada
e o ambiente pode restringir versionamento. A equipe deve testar esses recursos
na conta Learner Lab, sem desabilitar proteções para contornar erros.

Se uma permissão/serviço não estiver disponível, registre a limitação e não
introduza credenciais permanentes nem amplie roles indiscriminadamente. Para
migrar para uma conta AWS convencional: recrie/revise as roles com least
privilege, configure permissões de workload (preferencialmente IRSA ou EKS Pod
Identity), valide políticas de fila e ECR pull, aplique em ambiente de teste e
preserve/migre os States conforme uma janela controlada. A fila de respostas
compartilhada e o ALB existentes devem continuar únicos.

## Ordem de provisionamento

1. Criar/configurar o backend S3 e migrar o State compartilhado.
2. Inicializar e aplicar este repositório (`tech-challenge-oficina-k8s`).
3. Publicar/compartilhar outputs de rede, cluster, ECR e SQS.
4. Aplicar os recursos próprios de OS (`tech-challenge-oficina-database`),
   Execution (`tech-challenge-oficina-execution`) e o banco do Billing após
   decisão da equipe, cada qual com seu State.
5. Preparar secrets/identidades fora do Git e aplicar os workloads de cada
   serviço em seus repositórios ao mesmo cluster EKS.

O ALB e o Target Group atuais continuam associados à porta NodePort 30080 do
serviço principal. Não foram adicionadas regras/target groups para outras APIs:
domínios, caminhos, listeners, portas e ownership do AWS Load Balancer
Controller precisam ser acordados com a equipe e compatibilizados com os
manifests dos serviços antes de expor novas rotas.

## Validações e pendências

`terraform fmt`/`validate` verificam sintaxe e consistência local, não criam
recursos. `terraform plan` depende de credenciais, roles, quotas e permissões;
nenhum recurso deve ser considerado provisionado até confirmar o resultado na
AWS. Decisões ainda necessárias incluem roles IAM de runtime por serviço,
políticas SQS por role, exposição/roteamento compartilhado do ALB, namespace e
identidade de runtime do Execution, e tecnologia do banco do Billing.
