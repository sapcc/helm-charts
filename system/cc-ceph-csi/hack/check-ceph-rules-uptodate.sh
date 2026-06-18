#!/usr/bin/env bash

set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
alerts_file="${chart_dir}/alerts/ceph.alerts"
values_file="${chart_dir}/values.yaml"

if [[ $# -ge 1 ]]; then
  version="$1"
else
  version="$(sed -n 's#.*rook/ceph:\(v[0-9][^ "]*\).*#\1#p' "${values_file}" | head -n1)"
fi
[[ -n "${version}" ]] || { echo "ERROR: could not determine rook version; pass it as an argument" >&2; exit 2; }

url="https://raw.githubusercontent.com/rook/rook/${version}/deploy/examples/monitoring/localrules.yaml"
echo "vendored: ${alerts_file}"
echo "upstream: ${url}"

upstream="$(mktemp)"; trap 'rm -f "${upstream}"' EXIT

curl -fsSL "${url}" \
  | awk 'printing { print } /^spec:/ { printing = 1 }' \
  | sed 's/^  //' \
  > "${upstream}"

if diff -u "${alerts_file}" "${upstream}"; then
  echo "OK: ceph.alerts matches rook ${version} localrules.yaml"
else
  cat >&2 <<MSG

DRIFT: alerts/ceph.alerts differs from rook ${version} (see diff above).
Re-vendor: take the upstream spec body, de-indent by 2 spaces, overwrite
alerts/ceph.alerts. Do NOT add support_group here (it is injected at render time).
If this drift is from a rook bump, also update operator.image / appVersion.
MSG
  exit 1
fi
