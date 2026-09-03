# ADR-006: Estratégia de disponibilidade utilizando Deployment, Rolling Update e Health Checks

## Status

Aceito

## Contexto

A aplicação precisa permanecer disponível durante atualizações e deve ser capaz de identificar containers que não estão funcionando corretamente.

Também é necessário impedir que containers ainda não preparados recebam tráfego.

## Decisão

A aplicação será executada utilizando um Kubernetes Deployment.

O Deployment possui inicialmente duas réplicas.

### As atualizações utilizam a estratégia:

```yaml
strategy:
  type: RollingUpdate
```

### A configuração utilizada é:

maxSurge: 1
maxUnavailable: 0

## Também foram configuradas três probes:

### Liveness Probe

Utilizada para identificar containers que precisam ser reiniciados.

Endpoint:

/health/live/

### Readiness Probe

Utilizada para determinar quando o container está preparado para receber tráfego.

Endpoint:

/health/ready/

### Startup Probe

Utilizada para permitir que a aplicação tenha tempo suficiente para iniciar.

Endpoint:

/health/live/

## Consequências

### Positivas

-Atualizações podem ocorrer gradualmente.
-A configuração evita indisponibilidade planejada durante o Rolling Update.
-Containers que não respondem corretamente podem ser reiniciados.
-Pods que ainda não estão preparados não recebem tráfego.
-A aplicação possui maior tolerância a falhas.

### Negativas

-Os endpoints de health check precisam ser mantidos pela aplicação.
-Configurações incorretas das probes podem causar reinicializações.
-O processo de atualização pode ser mais lento.

## Alternativas consideradas

### Recreate

Não foi escolhido porque poderia causar indisponibilidade durante atualizações.

### Sem Health Checks

Não foi escolhido porque o Kubernetes não teria informações suficientes sobre o estado da aplicação.
