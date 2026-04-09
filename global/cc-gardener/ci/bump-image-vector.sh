#!/bin/sh -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CHART_FILE="${SCRIPT_DIR}/../Chart.yaml"
VALUES_FILE="${SCRIPT_DIR}/../values.yaml"

YQ_MAP_IMAGES='{"images":
  [.images[] |
    {
     "name": .name,
     "repository": .repository
    }
  ] | unique_by(.name) | sort_by(.name) | map(.repository |= (
        sub("^europe-docker.pkg.dev/", "keppel.global.cloud.sap/ccloud-europe-docker-pkg-dev-mirror/") |
        sub("^registry.k8s.io/", "keppel.global.cloud.sap/ccloud-registry-k8s-io-mirror/") |
        sub("^quay.io/","keppel.global.cloud.sap/ccloud-quay-mirror/") |
        sub("^gcr.io/", "keppel.global.cloud.sap/ccloud-gcr-mirror/") |
        sub("^ghcr.io/", "keppel.global.cloud.sap/ccloud-ghcr-io-mirror/") |
        sub("/gardener-project/public/", "/gardener-project/releases/")
    ))
}'

# TODO:
# public.ecr.aws -> mirror

# gardener operator
GARDENER_IV="$(curl -sL "https:/raw.githubusercontent.com/gardener/gardener/refs/tags/$(yq -r '.appVersion' "${CHART_FILE}")/imagevector/containers.yaml")"
echo "${GARDENER_IV}" | yq "${YQ_MAP_IMAGES}" |
  yq -i '.operator.imageVectorOverwrite = load_str("/dev/stdin")' "${VALUES_FILE}"

# etcd-druid sub-component
ETCD_DRUID_TAG="$(echo "${GARDENER_IV}" | yq '.images[]|select(.name=="etcd-druid")|.tag')"
curl -sL "https:/raw.githubusercontent.com/gardener/etcd-druid/refs/tags/${ETCD_DRUID_TAG}/internal/images/images.yaml" | yq "${YQ_MAP_IMAGES}" |
  yq -i '.operator.componentImageVectorOverwrites = ({"components": [{"name":"etcd-druid", "imageVectorOverwrite": load_str("/dev/stdin")}]} | to_yaml)' "${VALUES_FILE}"

# openstack extension
curl -sL "https:/raw.githubusercontent.com/gardener/gardener-extension-provider-openstack/refs/tags/$(yq -r '.extensions.openstack.version' "${VALUES_FILE}")/imagevector/images.yaml" | yq "${YQ_MAP_IMAGES}" |
  yq -i '.extensions.openstack.imageVectorOverwrite = load("/dev/stdin")' "${VALUES_FILE}"

# aws extension
curl -sL "https:/raw.githubusercontent.com/gardener/gardener-extension-provider-aws/refs/tags/$(yq -r '.extensions.aws.version' "${VALUES_FILE}")/imagevector/images.yaml" | yq "${YQ_MAP_IMAGES}" |
  yq -i '.extensions.aws.imageVectorOverwrite = load("/dev/stdin")' "${VALUES_FILE}"

# oidc-apps-controller extension
curl -sL "https:/raw.githubusercontent.com/gardener/oidc-apps-controller/refs/tags/$(yq -r '.extensions.oidcAppsController.version' "${VALUES_FILE}")/imagevector/images.yaml" | yq "${YQ_MAP_IMAGES}" |
  yq -i '.extensions.oidcAppsController.imageVectorOverwrite = load("/dev/stdin")' "${VALUES_FILE}"

# calico extension
CALICO_VERSION="$(yq -r '.extensions.calico.version' "${VALUES_FILE}")"
curl -sL "https:/raw.githubusercontent.com/gardener/gardener-extension-networking-calico/refs/tags/${CALICO_VERSION}/imagevector/images.yaml" | yq "${YQ_MAP_IMAGES}" |
  yq ".images[] |= select(.name == \"cni-plugins\").tag = \"${CALICO_VERSION}\"" | # this is a workaround for https://github.com/gardener/gardener-extension-networking-calico/pull/778
  yq -i '.extensions.calico.imageVectorOverwrite = load("/dev/stdin")' "${VALUES_FILE}"

# auditing extension
curl -sL "https:/raw.githubusercontent.com/gardener/gardener-extension-auditing/refs/tags/$(yq -r '.extensions.auditing.version' "${VALUES_FILE}")/imagevector/images.yaml" | yq "${YQ_MAP_IMAGES}" |
  yq -i '.extensions.auditing.imageVectorOverwrite = load("/dev/stdin")' "${VALUES_FILE}"
