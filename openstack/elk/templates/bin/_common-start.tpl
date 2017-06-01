#!/bin/bash

# on Ubuntu, python does not recognize the system certificate bundle
export OS_CACERT=/etc/ssl/certs/ca-certificates.crt
export OS_AUTH_URL="{{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}/v3"

# get K8S environment
export KUBE_NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)
export KUBE_POD_NAME=$HOSTNAME
curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$KUBE_NAMESPACE/pods/$KUBE_POD_NAME > /pod.json
export KUBE_POD_UID=$(jq -r ".metadata.uid" < /pod.json)
export KUBE_NODE_IP=$(jq -r ".status.hostIP" < /pod.json)
export KUBE_NODE_NAME=$(jq -r ".spec.nodeName" < /pod.json)
