#!/bin/bash

set -ex

# install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.10.2/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
mkdir /root/.kube/

# configure kubectl
SERVER=https://kubernetes.default
CA=$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 -w0 )
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# setup kubeconfig
echo "
apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    certificate-authority-data: ${CA}
    server: ${SERVER}
contexts:
- name: default-context
  context:
    cluster: default-cluster
    namespace: ${NAMESPACE}
    user: default-user
current-context: default-context
users:
- name: default-user
  user:
    token: ${TOKEN}
" > ~/.kube/config

# change permissions
chmod 644 ~/.kube/config

# test kubectl & config
kubectl version
kubectl -n ${NAMESPACE} get pods

# kill the memcached pod, since it might contain outdated cached content
memcached_pod=$(kubectl get pods -n ${NAMESPACE} -l app=keystone-memcached --no-headers -o=custom-columns=name:.metadata.name)
kubectl -n ${NAMESPACE} delete pod $memcached_pod

# scale down the postgress deployments
kubectl -n ${NAMESPACE} scale --replicas=0 deployment/keystone-pgmetrics --timeout=10s
kubectl -n ${NAMESPACE} scale --replicas=0 deployment/keystone-postgresql --timeout=10s
