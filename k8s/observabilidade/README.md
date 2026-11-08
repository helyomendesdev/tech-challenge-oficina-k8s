# Observabilidade do cluster — Metrics Server e New Relic (`nri-bundle`)

O agente APM que roda dentro dos pods da aplicação enxerga a aplicação, não o cluster. Para o
New Relic mostrar **CPU e memória por pod**, **réplicas desejadas × prontas do HPA** e **eventos
do Kubernetes** é preciso um agente no cluster: o chart `newrelic/nri-bundle`. O **Metrics Server**
entra no mesmo passo porque o HPA (`k8s/hpa.yaml`) não escala sem ele.

Os dois são instalados por um script, do mesmo jeito manual dos `kubectl apply` da aplicação — o
CD deste repositório só provisiona a infraestrutura com Terraform.

## Instalar

Pré-requisitos: `kubectl` e `helm` 3, kubeconfig apontando para o cluster, e o Secret
`newrelic-license` já criado no namespace `oficina` (é o mesmo que o Deployment da aplicação usa).

```bash
aws eks update-kubeconfig --name oficina-eks --region us-east-1
scripts/observabilidade.sh
```

O script é idempotente. Depois de um `terraform destroy`/`apply`, basta rodar de novo.

O que ele faz:

| Passo | O quê | Onde |
|---|---|---|
| 1 | `kubectl apply` do Metrics Server `v0.9.0` | `kube-system` |
| 2 | Copia a license key do Secret `oficina/newrelic-license` para `newrelic/newrelic-license` (Secrets são por namespace) | `newrelic` |
| 3 | `helm upgrade --install newrelic-bundle newrelic/nri-bundle --version 8.0.24 -f newrelic-values.yaml` | `newrelic` |
| 4 | Lista os pods e roda `kubectl top nodes` | — |

A license key nunca passa por arquivo versionado nem por `--set`: o chart lê do Secret
(`global.customSecretName` em [`newrelic-values.yaml`](newrelic-values.yaml)).

## Verificar

```bash
kubectl -n newrelic get pods            # todos Running: 1 kubelet por nó, 1 ksm, 1 kube-state-metrics, 1 kube-events
kubectl top nodes && kubectl top pods -n oficina
kubectl -n oficina get hpa               # TARGETS deixa de mostrar <unknown>
```

No New Relic, **Infrastructure → Kubernetes**, cluster `oficina-eks`. Ou por NRQL:

```sql
-- CPU e memória por pod da aplicação
FROM K8sContainerSample
SELECT average(cpuUsedCores), average(memoryWorkingSetBytes)
WHERE clusterName = 'oficina-eks' AND namespaceName = 'oficina'
FACET podName TIMESERIES

-- HPA: desejadas × atuais (é o gráfico do teste de carga)
FROM K8sHpaSample
SELECT latest(desiredReplicas), latest(currentReplicas), latest(maxReplicas)
WHERE clusterName = 'oficina-eks'
FACET displayName TIMESERIES

-- Eventos do cluster (restart, OOMKilled, BackOff)
FROM InfrastructureEvent
SELECT event.reason, event.message, event.involvedObject.name
WHERE clusterName = 'oficina-eks' AND event.involvedObject.namespace = 'oficina'
```

## O que está ligado e o que ficou fora

Os nós são `t3.small` (2 vCPU, 2 GiB). O chart completo não cabe ao lado dos pods da aplicação,
então só entra o que responde às perguntas acima:

| Componente | Estado | Motivo |
|---|---|---|
| `newrelic-infrastructure` (kubelet + ksm) | **ligado**, `lowDataMode` | É o que gera `K8sContainerSample`, `K8sPodSample`, `K8sHpaSample` |
| `kube-state-metrics` | **ligado** | Obrigatório para Deployments/HPA |
| `nri-kube-events` | **ligado** | Explica um restart durante o vídeo |
| `controlPlane` | desligado | Control plane do EKS é gerenciado pela AWS; o scraper só geraria erro |
| `newrelic-logging` (fluent-bit) | desligado | O agente APM já encaminha o log JSON do stdout; ligar duplicaria cada linha |
| `nri-metadata-injection` | desligado | Webhook que liga APM ↔ entidade K8s; exige restart dos pods da aplicação, fica para depois |
| `nri-prometheus`, Pixie, eBPF, operators | desligados | Fora do escopo e do orçamento |

Requests somados do que está ligado: ~100m de CPU e ~200 MB por nó (DaemonSet) mais ~140m e
~330 MB de Deployments, contra os 100m/256Mi de cada pod da aplicação.

## Desinstalar

```bash
helm -n newrelic uninstall newrelic-bundle
kubectl delete namespace newrelic
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml
```

## Limitações

- Ambiente AWS Academy é efêmero: o cluster some entre sessões, e com ele os agentes. O histórico
  fica no New Relic; a instalação precisa ser refeita a cada `terraform apply`.
- Sem `nri-metadata-injection`, a aba *Kubernetes* dentro do APM da aplicação fica vazia; os dados
  do cluster estão em *Infrastructure → Kubernetes*.
- `lowDataMode` coleta a cada 30 s e omite atributos raros. Para um teste de carga de minutos é
  suficiente.
