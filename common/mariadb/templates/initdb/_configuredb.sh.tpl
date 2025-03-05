#!/usr/bin/env ash
# shellcheck shell=ash
# shellcheck disable=SC2154
# shellcheck disable=SC1083

set -eou pipefail
set -x

DEPLOYMENT_NAME={{ include "fullName" . }}

# Get the pod name associated with the deployment
# becuase the pod name is dynamic, and kubectl cp command is working only with pods
# we need to get the pod name from the deployment

POD_NAME=$(kubectl get pods -l app="${DEPLOYMENT_NAME}" -o jsonpath='{.items[0].metadata.name}')

# Copy the secret file into the jobs /tmp directory
# The original secret files can not be copied directly via kubectl cp
cp -L /var/lib/initdb/init.sql /tmp/init.sql

# Copy the SQL script to the MariaDB container
kubectl cp /tmp/init.sql "${POD_NAME}":/var/opt/initdb.sql -c mariadb

# Run the SQL script
kubectl exec -c mariadb "${POD_NAME}" -- mariadb -uroot --batch -e "source /var/opt/initdb.sql"

{{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested }}
# shutdown linkerd containers
if command -v curl > /dev/null; then
  curl -X POST http://localhost:4191/shutdown || true
elif command -v wget > /dev/null; then
  wget -O- --post-data hello=shutdown http://0.0.0.0:4191/shutdown || true
else
  printf "POST /shutdown HTTP/1.0\r\n\r\n" | nc localhost 4191 || true
fi
{{- end }}
