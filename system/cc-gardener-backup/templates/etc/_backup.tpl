#!/usr/bin/env bash
set -euo pipefail

trap 'rm -rf "${gpg_key_dir}"; rm -rf /tmp/backup-dir; unset BACKUP_OS_APPLICATION_CREDENTIAL_SECRET BACKUP_OS_APPLICATION_CREDENTIAL_ID' EXIT ERR

cluster_backup_dir="${BACKUP_DIR:-/tmp/backup-dir}"
gpg_key_dir="${GPG_KEY_DIR:-/tmp/gpg-keys-$(date +%s)-$$}"
archive_name="$(date +"%y-%m-%dT%H-%M-%S")-${CONTEXT}-backup.tar.gz"
encrypted_filename="${archive_name}.gpg"
publickey_name="${REGION}-${PUBLIC_KEY_NAME}"
echo "Cluster backup directory: ${cluster_backup_dir}"
echo "GPG key directory: ${gpg_key_dir}"

#===================================================================================================
# Blacklists resources
#===================================================================================================

garden_blacklist=(
    componentstatuses
    tokenreviews.authentication.k8s.io
    selfsubjectaccessreviews.authorization.k8s.io
    selfsubjectrulesreviews.authorization.k8s.io
    subjectaccessreviews.authorization.k8s.io
    certificatesigningrequests.certificates.k8s.io
    bgpconfigurations.crd.projectcalico.org
    bgppeers.crd.projectcalico.org
    blockaffinities.crd.projectcalico.org
    clusterinformations.crd.projectcalico.org
    felixconfigurations.crd.projectcalico.org
    globalbgpconfigs.crd.projectcalico.org
    globalfelixconfigs.crd.projectcalico.org
    globalnetworkpolicies.crd.projectcalico.org
    globalnetworksets.crd.projectcalico.org
    hostendpoints.crd.projectcalico.org
    ipamblocks.crd.projectcalico.org
    ipamconfigs.crd.projectcalico.org
    ipamhandles.crd.projectcalico.org
    ippools.crd.projectcalico.org
    ciliumclusterwidenetworkpolicies.cilium.io
    ciliumendpoints.cilium.io
    ciliumidentities.cilium.io
    ciliumnetworkpolicies.cilium.io
    ciliumnodes.cilium.io
    nodes.metrics.k8s.io
    storagestates.migration.k8s.io
    storageversionmigrations.migration.k8s.io
    bindings
    localsubjectaccessreviews.authorization.k8s.io
    backendconfigs.cloud.google.com
    networkpolicies.crd.projectcalico.org
    networksets.crd.projectcalico.org
    capacityrequests.internal.autoscaling.k8s.io
    pods.metrics.k8s.io
    updateinfos.nodemanagement.gke.io
    selfsubjectreviews.authentication.k8s.io
    events
)

#===================================================================================================
# Functions
#===================================================================================================

function retry() {
    local retries=$1
    shift
    local command="$*"
    local count=0
    until [[ "$count" -ge "$retries" ]]; do
        if ${command}; then
            return 0
        else
            wait=$((2 ** count))
            count=$((count + 1))
            echo "Executing command: ${command} failed ${count} times. Waiting for ${wait} seconds before retrying."
            sleep "${wait}"
        fi
    done
    return 1
}

# shellcheck disable=SC2086
function filter_with_blacklist() {
    local resources="${1}"
    local -A blocked
    local -a blacklist_ref

    blacklist_ref=("${garden_blacklist[@]}")

    for item in "${blacklist_ref[@]}"; do
        blocked["${item}"]=1
    done

    local result=""
    for r in ${resources}; do
        if [[ -z "${blocked[${r}]+_}" ]]; then
            result+="${r} "
        fi
    done

    echo -n "${result% }"
}

function backup_global_resource() {
    resource=${1}

    kubectl_output=$(kubectl get "${resource}" -o=json) || {
        echo "ERROR: Failed to get resource '${resource}'"
        return 1
    }

    if [[ -z "${kubectl_output}" ]]; then
        echo "We didn't get anything when calling for resource ${resource}."
        return 1
    fi

    if ! jq --sort-keys \
        'del(
        .items[].metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
        .items[].metadata.annotations."control-plane.alpha.kubernetes.io/leader",
        .items[].metadata.uid,
        .items[].metadata.selfLink,
        .items[].metadata.resourceVersion,
        .items[].metadata.creationTimestamp,
        .items[].metadata.generation,
        .items[].status
    )' <<<"${kubectl_output}" >"${cluster_backup_dir}/${resource}.json"; then
        echo "Couldn't fetch valid json for resource ${resource}."
        return 1
    fi
    echo "Successfully backed up global resource: ${resource}"
}

function backup_ns_resource_together() {
    type="${1}"
    jq_del_args="${2}"

    echo "Backing up resource '${type}' by calling kubectl once for all namespaces."
    kubectl_output=$(kubectl get ${type} -o=json --all-namespaces --sort-by=.metadata.namespace) || {
        echo "ERROR: Failed to get resource '${type}' for all namespaces"
        return 1
    }


    if [[ -z "${kubectl_output}" ]]; then
        echo "We didn't get anything when calling for resource ${type}."
        return 1
    fi

    local filtered_output
    if ! filtered_output=$(jq --sort-keys \
        "select(.type!=\"kubernetes.io/service-account-token\") |
    del(
        ${jq_del_args}
    )" <<<"${kubectl_output}"); then
        echo "Couldn't process json for namespaced resource ${type}."
        return 1
    fi

    # Split items by namespace and write per-namespace files directly.
    local ns
    while IFS= read -r ns; do
        [[ "${ns}" == "garden-it" ]] && continue
        mkdir -p "${cluster_backup_dir}/${ns}"
        jq --sort-keys --arg ns "${ns}" \
            '{apiVersion: "v1", kind: "List", metadata: {resourceVersion: "", selfLink: ""}, items: [.items[] | select(.metadata.namespace == $ns)]}' \
            <<<"${filtered_output}" >"${cluster_backup_dir}/${ns}/${type}.json"
        echo "Successfully backed up ${type} in namespace: ${ns}"
    done < <(jq -r '[.items[].metadata.namespace] | unique[]' <<<"${filtered_output}")

    return 0
}

function backup_ns_resource_separately() {
    type="${1}"
    jq_del_args="${2}"
    namespaces="${3}"

    while read -r namespace; do
        if [[ ${namespace} = "garden-it" ]]; then
            continue
        fi
        kubectl_output=$(kubectl -n "${namespace}" get "${type}" -o=json) || {
            echo "ERROR: Failed to get resource '${type}' in namespace '${namespace}'"
            return 1
        }


        if [[ -z "${kubectl_output}" ]]; then
            echo "We didn't get anything when calling for resource ${type}."
            return 1
        fi

        items_count=$(jq '.items | length' <<<"${kubectl_output}")
        if [[ ${items_count} -eq 0 ]]; then
            echo "No resources of type ${type} found in namespace ${namespace}"
            continue
        fi
        echo "Found resources of type ${type} in namespace ${namespace}"

        mkdir -p "${cluster_backup_dir}/${namespace}"
        if ! jq --sort-keys \
            "select(.type!=\"kubernetes.io/service-account-token\") |
        del(
            ${jq_del_args}
        )" <<<"${kubectl_output}" >"${cluster_backup_dir}/${namespace}/${type}.json"; then
            echo "Couldn't fetch valid json for namespaced resource ${type} called separately."
            return 1
        fi
        echo "Successfully backed up ${type} in namespace: ${namespace}"
    done < <(echo "$namespaces")

    return 0
}

function backup_ns_resource() {
    type="${1}"
    namespaces="${2}"

    jq_del_args='.items[].metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
        .items[].metadata.annotations."control-plane.alpha.kubernetes.io/leader",
        .items[].spec.clusterIP,
        .items[].metadata.uid,
        .items[].metadata.selfLink,
        .items[].metadata.resourceVersion,
        .items[].metadata.creationTimestamp,
        .items[].metadata.generation'
    if [[ "$type" != 'meteringreports.metering.gardener.cloud' ]]; then
        jq_del_args+=',
        .items[].status'
    fi

    if ! backup_ns_resource_together "${type}" "${jq_del_args}"; then
        echo "Trying to fetch the resource ${type} separately by namespaces. There are ${namespaces_count} namespaces."
        if ! backup_ns_resource_separately "${type}" "${jq_del_args}" "${namespaces}"; then
            echo "ERROR: Failed to backup resource ${type} in all namespaces."
            exit 1
        fi
    fi
}

#===================================================================================================
# Validate Required Environment Variables
#===================================================================================================

required_vars=(
    "CONTEXT"
    "BACKUP_REGION"
    "REGION"
    "BACKUP_OS_APPLICATION_CREDENTIAL_ID"
    "BACKUP_OS_APPLICATION_CREDENTIAL_SECRET"
    "CONTAINER"
    "PUBLIC_KEY_NAME"
    "BACKUP_RETENTION_SECONDS"
    "OS_AUTH_URL"
)

echo "Validating required environment variables..."
missing_vars=()
for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        missing_vars+=("${var}")
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo "ERROR: Missing required environment variables:"
    printf '  - %s\n' "${missing_vars[@]}"
    exit 1
fi
echo "All required environment variables are set."


#===================================================================================================
# Kubernetes and OpenStack Authentication
#===================================================================================================

# The /usr/local/bin/kubectl wrapper requires SSO credentials (KUBELOGON_USER).
# In-cluster: skip it and use the versioned binary directly — it handles SA auth natively.
if [[ -n "${KUBERNETES_SERVICE_HOST:-}" ]]; then
    KUBECTL_VERSION="${KUBECTL_VERSION:-$(jq -r .kubectl < /usr/local/lib/kube-defaults.json)}"
    kubectl() { "kubectl-v${KUBECTL_VERSION}" "$@"; }
fi

kubectl cluster-info || {
    echo "ERROR: Failed to connect to Kubernetes cluster"
    exit 1
}

## Set value to not bloat logs with kubectl version info
export SKIP_VERSION_BANNERS=true

echo "Using injected OpenStack application credentials for Swift access in region ${BACKUP_REGION}"

echo "Retrieving Swift connection token"

RESPONSE=$(curl -isS -f --max-time 30 --connect-timeout 10 -X POST "$OS_AUTH_URL/auth/tokens" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg id "$BACKUP_OS_APPLICATION_CREDENTIAL_ID" \
    --arg secret "$BACKUP_OS_APPLICATION_CREDENTIAL_SECRET" \
    '{auth:{identity:{methods:["application_credential"],application_credential:{id:$id,secret:$secret}}}}')" ) || {
    echo "ERROR: Failed to authenticate with OpenStack to get Swift token"
    exit 1
}

TOKEN=$(echo "$RESPONSE" | grep -i '^X-Subject-Token:' | awk '{print $2}' | tr -d '\r')
if [[ -z "$TOKEN" ]]; then
    echo "ERROR: Failed to extract X-Subject-Token from OpenStack response"
    exit 1
fi

SWIFT_URL=$(echo "$RESPONSE" | sed -n '/^\r$/,$p' |jq -r '.token.catalog[] | select(.type == "object-store") | .endpoints[] | select(.interface == "public") | .url')
if [[ -z "$SWIFT_URL" ]] || [[ "$SWIFT_URL" == "null" ]]; then
    echo "ERROR: Failed to extract Swift URL from OpenStack catalog"
    exit 1
fi

mkdir -p "${gpg_key_dir}"
echo "Retriving object: "$/${CONTAINER}/${publickey_name}
curl -fL --max-time 60 --connect-timeout 10 \
  -H "X-Auth-Token: $TOKEN" \
  -o "${gpg_key_dir}/${publickey_name}" \
  "$SWIFT_URL/$CONTAINER/${publickey_name}" || {
    echo "ERROR: Failed to download GPG public key from Swift"
    exit 1
}

# Import GPG key and capture the fingerprint for later cleanup
gpg --import "${gpg_key_dir}/${publickey_name}" || {
    echo "ERROR: Failed to import GPG public key"
    exit 1
}

GPG_KEY_FINGERPRINT=$(gpg --with-colons --import-options show-only --import "${gpg_key_dir}/${publickey_name}" 2>/dev/null | awk -F: '/^fpr:/ { print $10; exit }') || {
    echo "ERROR: Failed to extract GPG key fingerprint"
    exit 1
}

if [[ -z "${GPG_KEY_FINGERPRINT}" ]]; then
    echo "ERROR: GPG key fingerprint is empty"
    exit 1
fi
echo "Imported GPG key with fingerprint: ${GPG_KEY_FINGERPRINT}"


#===================================================================================================
# Script Start
#===================================================================================================

mkdir -p "${cluster_backup_dir}"
pushd "${cluster_backup_dir}" 1>/dev/null || exit

# Get global and namespaced API resources with retry
if ! global_resources=$(retry 8 kubectl  api-resources -o name --namespaced=false); then
    echo "Failed to list global API resources."
    exit 1
fi


if ! ns_resources=$(retry 8 kubectl  api-resources -o name --namespaced=true); then
    echo "Failed to list namespaced API resources."
    exit 1
fi

# Apply blacklist filtering
global_resources="$(filter_with_blacklist "${global_resources}")"
ns_resources="$(filter_with_blacklist "${ns_resources}")"

echo "Will backup the following non-namespaced resources:"
echo "${global_resources}" | tr " " "\n" | nl
echo "Will backup the following namespaced resources:"
echo "${ns_resources}" | tr " " "\n" | nl

# Backup global resources
echo "Starting backup of global resources..."
for resource in ${global_resources}; do
    backup_global_resource "${resource}"
done
echo "All non-namespaced resources are saved."

# Get namespaces and backup namespaced resources in parallel
echo "Start namespaced resource export for all namespaces."
if ! namespaces=$(kubectl  get namespaces -o=jsonpath='{.items[*].metadata.name}'); then
    echo "command: kubectl  get namespaces -o=jsonpath='{.items[*].metadata.name}' failed."
    exit 1
fi
namespaces=$(echo "${namespaces}" | tr " " "\n")
namespaces_count=$(echo "${namespaces}" | wc -l)

# Backup namespaced resources
echo "Starting backup of namespaced resources..."
for type in ${ns_resources}; do
   backup_ns_resource "${type}" "${namespaces}"
done

echo "All namespaced resources are saved."
echo "Backup completed successfully."

tar -czf "/tmp/${archive_name}" -C "${cluster_backup_dir}"  . || {
    echo "ERROR: Failed to create tar archive"
    exit 1
}

mv "/tmp/${archive_name}" "${cluster_backup_dir}/${archive_name}"

gpg --always-trust -r "${GPG_KEY_FINGERPRINT}" --output "${encrypted_filename}" --encrypt "${cluster_backup_dir}/${archive_name}"  || {
    echo "ERROR: Failed to encrypt backup archive"
    exit 1
}

# Cleanup: Remove the GPG key from keyring
if [[ -n "${GPG_KEY_FINGERPRINT:-}" ]]; then
    echo "Removing imported GPG key from keyring..."
    gpg --batch --yes --delete-secret-keys "${GPG_KEY_FINGERPRINT}" 2>/dev/null || true
    gpg --batch --yes --delete-keys "${GPG_KEY_FINGERPRINT}" 2>/dev/null || {
        echo "WARNING: Failed to remove GPG key from keyring"
    }
fi

rm -rf "${gpg_key_dir}/${publickey_name}"

echo "Encrypted backup created: ${cluster_backup_dir}/${encrypted_filename}"

curl -f --max-time 30 --connect-timeout 10 -X PUT \
  -H "X-Auth-Token: $TOKEN" \
  -H "X-Delete-After: ${BACKUP_RETENTION_SECONDS}" \
  -T "${encrypted_filename}" \
  "$SWIFT_URL/$CONTAINER/${encrypted_filename}" || {
    echo "ERROR: Failed to upload encrypted backup to OpenStack Swift"
    exit 1
}

echo "Backup successfully uploaded to Swift container: ${CONTAINER}/${encrypted_filename}"

popd 1>/dev/null
