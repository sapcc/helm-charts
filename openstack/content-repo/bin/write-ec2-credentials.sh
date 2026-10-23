#!/usr/bin/env ash
# shellcheck shell=ash
# shellcheck disable=SC3010

# This is the entrypoint script for the "write-creds" container of the issue-ec2-credentials Job.

set -eou pipefail
[[ ${DEBUG:-} != false ]] && set -x

cat >secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: s3-proxy-ec2-credentials
  ownerReferences:
    - apiVersion: apps/v1
      kind: Deployment
      name: s3-proxy
      uid: $(kubectl get deployment s3-proxy -o jsonpath='{.metadata.uid}')
data:
  access-key: $(base64 -w0 < access-key)
  secret-key: $(base64 -w0 < secret-key)
EOF

kubectl apply -f secret.yaml
