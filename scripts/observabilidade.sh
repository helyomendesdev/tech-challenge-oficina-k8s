#!/usr/bin/env bash
# Instala no cluster do kubeconfig atual:
#   1. Metrics Server  — metrica de CPU/memoria que o HPA (k8s/hpa.yaml) consome.
#   2. nri-bundle      — agente Kubernetes do New Relic (CPU/memoria por pod,
#                        replicas do HPA, eventos), com k8s/observabilidade/newrelic-values.yaml.
#
# Idempotente: pode rodar de novo apos recriar o cluster (terraform apply) ou
# para atualizar versao. Nao mexe em nada do namespace da aplicacao alem de LER
# o Secret newrelic-license.
#
# Uso:
#   aws eks update-kubeconfig --name oficina-eks --region us-east-1
#   scripts/observabilidade.sh
#
# Variaveis opcionais:
#   NEW_RELIC_LICENSE_KEY   se nao definida, e lida do Secret newrelic-license do namespace da app
#   CLUSTER_NAME            default oficina-eks (vira clusterName no New Relic)
#   APP_NAMESPACE           default oficina
#   NR_NAMESPACE            default newrelic
#   METRICS_SERVER_VERSION  default v0.9.0
#   NRI_BUNDLE_VERSION      default 8.0.24
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-oficina-eks}"
APP_NAMESPACE="${APP_NAMESPACE:-oficina}"
NR_NAMESPACE="${NR_NAMESPACE:-newrelic}"
METRICS_SERVER_VERSION="${METRICS_SERVER_VERSION:-v0.9.0}"
NRI_BUNDLE_VERSION="${NRI_BUNDLE_VERSION:-8.0.24}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALUES_FILE="${REPO_ROOT}/k8s/observabilidade/newrelic-values.yaml"

for bin in kubectl helm; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERRO: '$bin' nao encontrado no PATH." >&2; exit 1; }
done
[ -f "$VALUES_FILE" ] || { echo "ERRO: values nao encontrado em $VALUES_FILE" >&2; exit 1; }

echo "==> Cluster atual: $(kubectl config current-context)"
kubectl cluster-info >/dev/null

# ------------------------------------------------------------------ 1. Metrics Server
echo "==> Metrics Server ${METRICS_SERVER_VERSION}"
kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_SERVER_VERSION}/components.yaml"
kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s

# ------------------------------------------------------------------ 2. License key
if [ -z "${NEW_RELIC_LICENSE_KEY:-}" ]; then
  NEW_RELIC_LICENSE_KEY="$(kubectl -n "$APP_NAMESPACE" get secret newrelic-license \
    -o jsonpath='{.data.NEW_RELIC_LICENSE_KEY}' 2>/dev/null | base64 -d || true)"
fi
if [ -z "$NEW_RELIC_LICENSE_KEY" ]; then
  echo "ERRO: defina NEW_RELIC_LICENSE_KEY ou crie antes o Secret newrelic-license no namespace ${APP_NAMESPACE}" >&2
  echo "      (kubectl create secret generic newrelic-license -n ${APP_NAMESPACE} --from-literal=NEW_RELIC_LICENSE_KEY=<chave>)" >&2
  exit 1
fi

# Secrets sao por namespace: o chart le a chave de um Secret no namespace dele.
kubectl create namespace "$NR_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n "$NR_NAMESPACE" create secret generic newrelic-license \
  --from-literal=NEW_RELIC_LICENSE_KEY="$NEW_RELIC_LICENSE_KEY" \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
unset NEW_RELIC_LICENSE_KEY

# ------------------------------------------------------------------ 3. nri-bundle
echo "==> nri-bundle ${NRI_BUNDLE_VERSION} (cluster=${CLUSTER_NAME}, namespace=${NR_NAMESPACE})"
helm repo add newrelic https://helm-charts.newrelic.com >/dev/null 2>&1 || true
helm repo update newrelic >/dev/null
helm upgrade --install newrelic-bundle newrelic/nri-bundle \
  --namespace "$NR_NAMESPACE" \
  --version "$NRI_BUNDLE_VERSION" \
  -f "$VALUES_FILE" \
  --set global.cluster="$CLUSTER_NAME" \
  --wait --timeout 5m

# ------------------------------------------------------------------ 4. Verificacao
echo
echo "==> Pods do New Relic"
kubectl -n "$NR_NAMESPACE" get pods -o wide
echo
echo "==> Metrics Server respondendo (pode levar ~1 min apos a instalacao)"
kubectl top nodes || echo "   ainda sem metrica; repita 'kubectl top nodes' em 1 minuto"
echo
cat <<EOF
Pronto. Em 2-3 minutos os dados aparecem no New Relic:
  Infrastructure > Kubernetes > cluster '${CLUSTER_NAME}'
  NRQL: FROM K8sContainerSample SELECT average(cpuUsedCores), average(memoryWorkingSetBytes)
        WHERE clusterName = '${CLUSTER_NAME}' AND namespaceName = '${APP_NAMESPACE}' FACET podName TIMESERIES
EOF
