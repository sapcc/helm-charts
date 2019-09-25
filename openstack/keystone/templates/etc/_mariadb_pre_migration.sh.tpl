#!/bin/bash

set -ex

# install psql2mysql
git clone https://github.com/sapcc/psql2mysql /tmp/psql2mysql
pip install --upgrade pip  --trusted-host pypi.org --trusted-host files.pythonhosted.org
cd /tmp/psql2mysql; pip install -r requirements.txt --trusted-host pypi.org --trusted-host files.pythonhosted.org ; python setup.py install

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

# Create the keystone schema in mariadb
echo "[DEFAULT]" > /etc/keystone/keystone.conf
echo "[database]" >> /etc/keystone/keystone.conf
echo "connection = ${MARIADB_URL}" >> /etc/keystone/keystone.conf

FILE=/etc/keystone/keystone.conf
if test -f "$FILE"; then
    echo ">>>> ${SERVICE} config found!"
    cat ${FILE}
else
    echo ">>>> ${SERVICE} config missing!"
    exit 1
fi

keystone-manage db_sync || exit 1

# run psql2mysql pre-check
OUTPUT="$(psql2mysql --source ${POSTGRES_URL} precheck)"
echo "${OUTPUT}"

if [[ ${OUTPUT} == *"Success. No errors found during prechecks."* ]]
then
   echo " ========= Psql2mysql percheck OK ========= "
else
   echo ">>>>>> PRECHECK FAILED. ABORTING!!!"
   exit 1
fi

# scale down the respective Deployments
kubectl -n ${NAMESPACE} scale --replicas=0 deployment/keystone-api --timeout=10s
kubectl -n ${NAMESPACE} scale --replicas=0 deployment/keystone-memcached --timeout=10s
sleep 20

{{- if .Values.postgresql.backup.enabled }}
# create a database backup
kubectl exec -it `kubectl get pods --selector=app=keystone-postgresql | awk '{ print $1 }' | tail -1` --container=backup -- bash -c 'BACKUP_PGSQL_FULL="1 mins" /usr/local/sbin/db-backup.sh' || exit 1
{{- end }}

# Do an actual migration to MariaDB
psql2mysql --source "${POSTGRES_URL}" --target "${MARIADB_URL}" migrate || exit 1

