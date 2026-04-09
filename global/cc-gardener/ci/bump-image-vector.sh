#!/bin/sh -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CHART_FILE="${SCRIPT_DIR}/../Chart.yaml"
VALUES_FILE="${SCRIPT_DIR}/../values.yaml"

curl -sL "https://github.com/gardener/gardener/raw/refs/tags/$(yq -r '.appVersion' "${CHART_FILE}")/imagevector/containers.yaml" | yq '
{"images":
  [.images[] |
    {
     "name": .name,
     "repository": .repository
    }
  ] | unique_by(.name) | sort_by(.name) | map(.repository |= (
        sub("^europe-docker.pkg.dev/", "keppel.global.cloud.sap/ccloud-europe-docker-pkg-dev-mirror/") |
        sub("^registry.k8s.io/", "keppel.global.cloud.sap/ccloud-registry-k8s-io-mirror/") |
        sub("^quay.io/","keppel.global.cloud.sap/ccloud-quay-mirror/") |
        sub("^gcr.io/", "keppel.global.cloud.sap/ccloud-gcr-mirror/")
    ))
}' | yq -i '.operator.imageVectorOverwrite = load_str("/dev/stdin")' "${VALUES_FILE}"
