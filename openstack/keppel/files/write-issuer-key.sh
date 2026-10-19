#!/usr/bin/env ash
# shellcheck shell=ash
# shellcheck disable=SC3010

# This is the entrypoint script for the "write-secret" container of the cronjob "keppel-generate-issuer-key".
# The previous contents of the secret (if any) are given in `/keys`.
# The newly generated issuer key is in `/work/current-key.pem`.

set -eou pipefail

if [[ -f /keys/current-key.pem ]]; then
  cp /keys/current-key.pem /work/previous-key.pem
else
  # On first run, the secret is empty, so we do not have a previous key.
  # Putting the same key twice is a safe fallback that allows keeping the same secret structure in this case.
  cp /work/current-key.pem /work/previous-key.pem
fi

echo -n "data:
  current-key.pem:  $(cat /work/current-key.pem  | base64 -w0)
  previous-key.pem: $(cat /work/previous-key.pem | base64 -w0)
" > /work/patch.yaml

kubectl patch secret "$SECRET_NAME" --patch-file=/work/patch.yaml
