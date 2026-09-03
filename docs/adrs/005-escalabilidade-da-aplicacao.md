# ADR-005: Escalabilidade horizontal utilizando HPA

## Status

Aceito

## Contexto

A aplicação precisa possuir capacidade de aumentar ou reduzir o número de réplicas de acordo com a utilização dos recursos.

Manter um número fixo de Pods poderia resultar em:

- utilização excessiva de recursos;
- indisponibilidade durante períodos de maior carga;
- desperdício de recursos durante períodos de baixa utilização.

## Decisão

Foi utilizado o Horizontal Pod Autoscaler (HPA) do Kubernetes.

A aplicação possui:

- mínimo de 2 réplicas;
- máximo de 6 réplicas.

O HPA utiliza a utilização média de CPU como métrica.

### O alvo configurado é:

50% de utilização média de CPU

### O Deployment possui inicialmente duas réplicas.

Também foram configurados comportamentos específicos para scale up e scale down.

O scale down possui uma janela de estabilização de 60 segundos.

## Consequências

### Positivas

-A aplicação pode aumentar o número de Pods durante períodos de maior utilização.
-A quantidade de Pods pode ser reduzida durante períodos de menor carga.
-A infraestrutura possui maior capacidade de adaptação à carga.
-O Deployment mantém pelo menos duas réplicas.

### Negativas

-O HPA depende da disponibilidade de métricas.
-É necessário configurar corretamente requests e limits dos containers.
-O aumento do número de Pods depende da disponibilidade de recursos nos nodes.

## Alternativas consideradas

### Número fixo de réplicas

Não foi escolhido porque não permitiria adaptação automática à carga.

### Escalabilidade manual

Não foi escolhida porque exigiria intervenção manual durante alterações de carga.
