#!/bin/bash

#set -x;

# Path to the OpenSearch hash.sh script
export OPENSEARCH_BASE="/usr/share/opensearch"
export HASH_SCRIPT_PATH="$OPENSEARCH_BASE/plugins/opensearch-security/tools/hash.sh"

mkdir -p $OPENSEARCH_BASE/config/security
cp $OPENSEARCH_BASE/config/opensearch-security/*.yml $OPENSEARCH_BASE/config/security/

export USER_NAME=`grep "^[a-z0-9].*" $OPENSEARCH_BASE/config/security/internal_users.yml |tr -d ":"`

echo $USER_NAME

for i in $USER_NAME; do
  echo USERNAME=$i
  PASSWORD_VALUE=`yq ".$i.hash" $OPENSEARCH_BASE/config/security/internal_users.yml`
  if [[ "$PASSWORD_VALUE" != null ]]; then
    if [[ $PASSWORD_VALUE =~ "vault" ]]; then
      echo "check vault injector or password, looks like it was not retrieved from vaul"
      exit 1
    else
      HASHED_VALUE=`$OPENSEARCH_BASE/plugins/opensearch-security/tools/hash.sh -p "$PASSWORD_VALUE" | tail -1`
      # Check if the hashing was successful
      if [ -z "$HASHED_VALUE" ]; then
        echo "Error: Failed to hash the secret value."
        exit 1
      fi
    # Update the internal_users.yaml with the hashed value

      yq eval ".$i.hash |= \"$HASHED_VALUE\"" -i $OPENSEARCH_BASE/config/security/internal_users.yml
      # Check if the insertion was successful
      if [ $? -ne 0 ]; then
        echo "Error: Failed to insert the hashed value into internal_users.yaml."
        exit 1
      fi
    fi
  else
      echo USER $i has no password set, no hashing
  fi
done

$OPENSEARCH_BASE/plugins/opensearch-security/tools/securityadmin.sh -icl -key $OPENSEARCH_BASE/config/certs/admin/tls.key -cert  $OPENSEARCH_BASE/config/certs/admin/tls.crt -cacert $OPENSEARCH_BASE/config/certs/admin/ca.crt -cd $OPENSEARCH_BASE/config/security/ -h opensearch-logs-client.{{ .Values.global.clusterType}}.{{ .Values.global.region }}.{{ .Values.global.tld }}
