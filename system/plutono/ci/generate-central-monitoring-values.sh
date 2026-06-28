#!/usr/bin/env bash
set -euo pipefail

# Generates a runtime Helm values file for central Plutono datasources.
# Secrets are read from cluster and written to a temporary output path only.
# Nothing is committed to git.

CONTEXT="${CONTEXT:-pg-p-eu-de-1}"
NAMESPACE="${NAMESPACE:-garden}"
OUT_FILE="${OUT_FILE:-/tmp/central-monitoring-values.generated.yaml}"

# Output header
cat >"${OUT_FILE}" <<'YAML'
global:
  registry: "replace-me"
  registryK8sIoMirror: "replace-me"
  ghcrIoMirror: "replace-me"
  region: eu-de-1
  domain: persephone.eu-de-1.cloud.sap

plutono:
  image: credativ/plutono
  image_version: latest
  mode: operator

  auth:
    basic_auth:
      enabled: true
    ldap:
      enabled: true

  endpoint:
    host:
      public: plutono-central.runtime.prod.persephone.eu-de-1.cloud.sap

  gitsync:
    enabled: false

  centralMonitoring:
    enabled: true
    datasources:
YAML

# Discover all *.monitoring secrets from source-of-truth namespace.
# Use a Bash 3 compatible loop (mapfile is not available on macOS default Bash).
MONITORING_SECRETS=()
while IFS= read -r seed; do
  MONITORING_SECRETS+=("${seed}")
done < <(
  u8s kubectl --context "${CONTEXT}" -n "${NAMESPACE}" get secrets -o name \
    | sed -n 's|^secret/\(.*\)\.monitoring$|\1|p' \
    | sort
)

if [[ ${#MONITORING_SECRETS[@]} -eq 0 ]]; then
  echo "No *.monitoring secrets found in ${CONTEXT}/${NAMESPACE}" >&2
  exit 1
fi

for seed in "${MONITORING_SECRETS[@]}"; do
  url="$(u8s kubectl --context "${CONTEXT}" -n "${NAMESPACE}" get secret "${seed}.monitoring" -o jsonpath='{.metadata.annotations.prometheus-url}')"
  pass="$(u8s kubectl --context "${CONTEXT}" -n "${NAMESPACE}" get secret "${seed}.monitoring" -o jsonpath='{.data.password}' | base64 -d)"

  default_flag="false"
  if [[ "${seed}" == "eude1-01p" ]]; then
    default_flag="true"
  fi

  cat >>"${OUT_FILE}" <<YAML
      - name: prometheus-${seed%p}
        type: prometheus
        access: proxy
        url: ${url}
        basicAuth: true
        basicAuthUser: admin
        isDefault: ${default_flag}
        jsonData:
          timeInterval: 1m
        secureJsonData:
          basicAuthPassword: |
            ${pass}

YAML
done

cat >>"${OUT_FILE}" <<'YAML'
authentication:
  enabled: false

ingress:
  enabled: true
  global: false
YAML

echo "Generated ${OUT_FILE} with ${#MONITORING_SECRETS[@]} datasources."
echo "Use it with: helm upgrade --install <release> system/plutono -f ${OUT_FILE} ..."
