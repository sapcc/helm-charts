#!/bin/bash

#set -x;

# Path to the OpenSearch hash.sh script
export OPENSEARCH_BASE="/usr/share/opensearch"
export HASH_SCRIPT_PATH="$OPENSEARCH_BASE/plugins/opensearch-security/tools/hash.sh"

mkdir -p $OPENSEARCH_BASE/config/security
cp $OPENSEARCH_BASE/config/opensearch-security/*.yml $OPENSEARCH_BASE/config/security/

export USER_NAME=`grep "^[a-z0-9].*" $OPENSEARCH_BASE/config/security/internal_users.yml |tr -d ":"`

echo "Found users: $USER_NAME"

for i in $USER_NAME; do
  echo "Processing user: $i"
  PASSWORD_VALUE=`yq ".$i.hash" $OPENSEARCH_BASE/config/security/internal_users.yml`
  if [[ "$PASSWORD_VALUE" != null ]]; then
    if [[ $PASSWORD_VALUE =~ "vault" ]]; then
      echo "ERROR: user $i - vault reference not resolved, check vault injector"
      exit 1
    else
      echo "  Hashing password for $i..."
      HASHED_VALUE=`$OPENSEARCH_BASE/plugins/opensearch-security/tools/hash.sh -p "$PASSWORD_VALUE" | grep '^\$2'`
      # Check if the hashing was successful
      if [ -z "$HASHED_VALUE" ]; then
        echo "ERROR: Failed to hash password for $i (hash.sh produced no \$2 output)"
        exit 1
      fi
      echo "  Hash generated for $i (${#HASHED_VALUE} chars, starts with ${HASHED_VALUE:0:7})"
    # Update the internal_users.yaml with the hashed value
      yq eval ".$i.hash |= \"$HASHED_VALUE\"" -i $OPENSEARCH_BASE/config/security/internal_users.yml
      # Check if the insertion was successful
      if [ $? -ne 0 ]; then
        echo "ERROR: Failed to write hash for $i into internal_users.yml"
        exit 1
      fi
      echo "  Hash written for $i"
    fi
  else
      echo "  User $i has no password set, skipping"
  fi
done

echo "All users hashed successfully, uploading security config..."
$OPENSEARCH_BASE/plugins/opensearch-security/tools/securityadmin.sh -icl -key $OPENSEARCH_BASE/config/certs/admin/tls.key -cert  $OPENSEARCH_BASE/config/certs/admin/tls.crt -cacert $OPENSEARCH_BASE/config/certs/rest/ca.crt -cd $OPENSEARCH_BASE/config/security/ -h opensearch-logs-client.{{ .Values.global.clusterType}}.{{ .Values.global.region }}.{{ .Values.global.tld }}
