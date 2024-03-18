#!/bin/bash
# service marked itself ready
grep 'ready' /etc/manila/probe
export SERVICE_EXIT_CODE=$?
# rabbitmq bindings exist
/etc/manila/rabbitmqadmin -H {{ .Release.Name }}-rabbitmq -u admin -p {{ .Values.rabbitmq.users.admin.password }} list bindings | grep $(hostname)
export BINDINGS_EXIT_CODE=$?
# rabbitmq has no uncollected messages
/etc/manila/rabbitmqadmin -H {{ .Release.Name }}-rabbitmq -u admin -p {{ .Values.rabbitmq.users.admin.password }} list queues -f tsv| grep $(hostname)|cut -f 2|grep -w 0
export QUEUES_EXIT_CODE=$?
{{- if .Values.pod.health.use_agent}}
# service is up via database periodic report
openstack-agent-liveness --component manila --config-dir /etc/manila --config-dir /etc/manila/manila.conf.d/
{{- end }}
export AGENT_LIVE_CODE=$?
exit $(($SERVICE_EXIT_CODE + $BINDINGS_EXIT_CODE + $QUEUES_EXIT_CODE + $AGENT_LIVE_CODE))
