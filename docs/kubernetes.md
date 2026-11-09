# Kubernetes — referência de configuração

Valores concretos dos manifests em `k8s/`. Para o raciocínio arquitetural (por que Deployment + HPA + Job, por que NodePort em vez de Ingress), veja [architecture.md](architecture.md) e os ADRs [004](adrs/004-exposicao-da-aplicacao-com-alb-e-nodeport.md), [005](adrs/005-escalabilidade-da-aplicacao.md), [006](adrs/006-disponibilidade-e-atualizacao-da-aplicacao.md) e [008](adrs/008-execucao-de-migrations-com-job.md).

## Namespace

Todos os recursos da aplicação vivem no namespace `oficina` (`k8s/namespace.yaml`).

## Deployment (`k8s/deployment.yaml`)

| Item | Valor |
| --- | --- |
| Réplicas iniciais | 2 |
| Estratégia | `RollingUpdate` (`maxSurge: 1`, `maxUnavailable: 0`) |
| Imagem | `<ECR_IMAGE>` (Amazon ECR `oficina-api`), via `imagePullSecrets: ecr-registry-secret` |
| Requests | CPU `100m`, memória `256Mi` |
| Limits | CPU `500m`, memória `512Mi` |
| Configuração (`envFrom`) | ConfigMap `oficina-config`; Secrets `oficina-secret`, `oficina-auth`, `newrelic-license` (`optional: true`) |

## Probes

| Probe | Endpoint | Parâmetros |
| --- | --- | --- |
| Startup | `/health/live/` | `initialDelaySeconds: 3`, `periodSeconds: 10`, `failureThreshold: 30` |
| Liveness | `/health/live/` | `initialDelaySeconds: 10`, `periodSeconds: 20`, `timeoutSeconds: 5` |
| Readiness | `/health/ready/` | `initialDelaySeconds: 5`, `periodSeconds: 10`, `timeoutSeconds: 5` — também usado pelo health check do Target Group do ALB |

## Service (`k8s/service.yaml`)

Tipo `NodePort`: porta `8000` → `targetPort 8000` → `nodePort 30080` (mesma porta configurada no Target Group do ALB — ver [rede-e-seguranca.md](rede-e-seguranca.md)).

## Horizontal Pod Autoscaler (`k8s/hpa.yaml`)

| Configuração | Valor |
| --- | --- |
| `minReplicas` / `maxReplicas` | 2 / 6 |
| Métrica | CPU, `averageUtilization: 50` |
| `scaleUp` | sem estabilização (`0s`); até `+2` pods ou `+100%` a cada 15s (o que for maior) |
| `scaleDown` | estabilização de `60s`; até `-50%` a cada 15s |

Depende do Kubernetes Metrics Server para coletar as métricas de CPU dos Pods.

## Migration Job (`k8s/migration-job.yaml`)

Executa `python manage.py migrate --noinput` com a mesma imagem da aplicação, separado do Deployment (evita que cada réplica rode a migration individualmente). `backoffLimit: 3`, `restartPolicy: Never`, `ttlSecondsAfterFinished: 300` (remoção automática do Job 5 minutos após a conclusão).

## ConfigMap e Secrets

Não sensível (ConfigMap `oficina-config`, `k8s/configmap.yaml`): `DJANGO_DEBUG`, `DJANGO_SETTINGS_MODULE`, `DJANGO_ALLOWED_HOSTS`, `DB_HOST`, `DB_PORT`, `SECURE_SSL_REDIRECT`, `DJANGO_LOG_FILE`, `STATIC_ROOT`, e as variáveis de observabilidade `NEW_RELIC_APP_NAME` (`oficina-api-hml`), `NEW_RELIC_DISTRIBUTED_TRACING_ENABLED`, `NEW_RELIC_APPLICATION_LOGGING_FORWARDING_ENABLED` (encaminhamento de logs do agente New Relic ligado pelo PR #18), `SERVICE_NAME`, `SERVICE_ENVIRONMENT` e `SERVICE_VERSION`.

Sensível (Secrets — nunca versionados com valor real; o repositório só mantém os arquivos `*.example.yaml`):

* `oficina-secret`: `DJANGO_SECRET_KEY`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `OBSERVABILIDADE_SALT` (salt do hash de CPF nos logs/eventos, exclusivo por ambiente);
* `oficina-auth`: `AUTH_JWT_PUBLIC_KEY_B64` — chave pública para validar o JWT emitido pelo repositório `tech-challenge-oficina-auth`;
* `newrelic-license`: `NEW_RELIC_LICENSE_KEY`, opcional — sem ele a aplicação sobe normalmente, apenas sem APM.
