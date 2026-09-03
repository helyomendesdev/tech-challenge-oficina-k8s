# ADR-008: Execução das migrations utilizando Kubernetes Job

## Status

Aceito

## Contexto

A aplicação Django possui migrations que precisam ser executadas para atualizar a estrutura do banco de dados.

Executar migrations durante a inicialização de cada Pod poderia causar concorrência entre múltiplas réplicas.

Como a aplicação possui mais de uma réplica, é necessário evitar que múltiplos containers executem migrations simultaneamente.

## Decisão

As migrations serão executadas utilizando um Kubernetes Job separado.

### O Job executa:

python manage.py migrate --noinput

### O Job possui:

restartPolicy: Never;
backoffLimit: 3;
ttlSecondsAfterFinished: 300.

### O Job utiliza:

a mesma imagem da aplicação;
ConfigMap;
Secret.

## Consequências

### Positivas

-As migrations são separadas da execução normal da aplicação.
-Evita executar migrations em todos os Pods.
-Permite acompanhar o resultado da execução.
-Permite repetir o Job caso necessário.

### Negativas

-O processo de deploy precisa considerar a execução do Job.
-É necessário definir corretamente a ordem entre migrations e atualização da aplicação.
-Migrations incompatíveis podem afetar versões anteriores da aplicação durante Rolling Updates.

## Alternativas consideradas

### Executar migrations no startup do container

Não foi escolhido porque múltiplos Pods poderiam executar migrations simultaneamente.

### Executar migrations manualmente

Não foi escolhido porque aumentaria a dependência de intervenção manual durante o deploy.
