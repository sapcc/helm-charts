#!/bin/bash

# check, that all used variables are set
if [ "$GF_SECURITY_ADMIN_USER" = "" ]; then
  echo "ERROR: GF_SECURITY_ADMIN_USER not set, please set gf.security.admin.user in the secrets"
  exit 1
fi

if [ "$GF_SECURITY_ADMIN_PASSWORD" = "" ]; then
  echo "ERROR: GF_SECURITY_ADMIN_PASSWORD not set, please set gf.security.admin.password in the secrets"
  exit 1
fi

if [ "$GRAFANA_LOCAL_USER" = "" ]; then
  echo "INFO: GRAFANA_LOCAL_USER not set, please set grafana.local.user in the secrets"
  exit 1
fi

if [ "$GRAFANA_LOCAL_PASSWORD" = "" ]; then
  echo "INFO: GRAFANA_LOCAL_PASSWORD not set, please set grafana.local.password in the secrets"
  exit 1
fi

# create a local user, which can be used to login when keystone is down
echo ""
echo "creating the local user $GRAFANA_LOCAL_USER - this might fail if rerun with persistent storage"
echo -n "==> "
# there is no more curl in the original grafana container, so we do this post call with netcat (nc)
#curl -s http://$GF_SECURITY_ADMIN_USER:$GF_SECURITY_ADMIN_PASSWORD@localhost:3000/api/admin/users -X POST -H 'Content-Type: application/json;charset=utf-8' --data-binary "{\"name\":\"Local User\",\"email\":\"\",\"login\":\"$GRAFANA_LOCAL_USER\",\"password\":\"$GRAFANA_LOCAL_PASSWORD\"}"
AUTHSTRING=$(echo -n $GF_SECURITY_ADMIN_USER:$GF_SECURITY_ADMIN_PASSWORD | base64)
PAYLOAD="{\"name\":\"Local User\",\"email\":\"\",\"login\":\"$GRAFANA_LOCAL_USER\",\"password\":\"$GRAFANA_LOCAL_PASSWORD\"}"
REQUEST="POST /api/admin/users HTTP/1.1\r\nHost: localhost\r\nAuthorization: Basic $AUTHSTRING\r\nContent-type: application/json;charset=utf-8\r\nContent-length: $(echo -n $mycontent | wc -c)\r\nConnection: Close\r\n\r\n$PAYLOAD"
echo -ne "$REQUEST" | nc localhost 3000
