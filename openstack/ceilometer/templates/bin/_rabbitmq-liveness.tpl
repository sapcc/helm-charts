{{- define "rabbitmq_liveness_tpl" -}}
#!/bin/bash

# do some tasks required for all ceilometer containers
. /container.init/common-start

# run rabbitmq aliveness test
#curl -m 30 -s http://guest:{{.Values.ceilometer_admin_password}}@localhost:{{.Values.ceilometer_rabbitmq_port_mgmt}}/api/aliveness-test/%2F | grep -q '"status":"ok"'
rabbitmqctl -n ceilometer-rabbitmq@ceilometer-rabbitmq node_health_check
CHECKRESULT=$?

RESTARTRESULT=0
if [ -f /restartme ]; then
  RESTARTRESULT=1
fi

if [ "X$CHECKRESULT" = "X0" ] && [ "X$RESTARTRESULT" = "X0" ]; then
  exit 0
else
  exit 1
fi
{{- end -}}
