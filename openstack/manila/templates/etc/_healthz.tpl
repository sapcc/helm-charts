#!/bin/bash
# service marked itself ready
grep 'ready' /etc/manila/probe
export SERVICE_EXIT_CODE=$?
# rabbitmq bindings exist
curl -s --netrc-file /etc/manila/manila.conf.d/netrc {{ include "manila.rabbitmq_service" . }}:{{ .Values.rabbitmq.ports.management }}/api/bindings | sed 's/},{/},\n{/g' | grep $(hostname) >/dev/null
export BINDINGS_EXIT_CODE=$?
# rabbitmq has no uncollected messages
curl -s --netrc-file /etc/manila/manila.conf.d/netrc "{{ include "manila.rabbitmq_service" . }}:{{ .Values.rabbitmq.ports.management }}/api/queues?disable_stats=true&enable_queue_totals=true" | sed 's/},{/},\n{/g' | grep $(hostname) | sed -n 's/.*"messages":\([0-9]*\).*/\1/p' | grep -w 0 >/dev/null
export QUEUES_EXIT_CODE=$?
{{- if .Values.pod.health.use_agent}}
# service is up via database periodic report
openstack-agent-liveness --component manila --config-dir /etc/manila --config-dir /etc/manila/manila.conf.d/
{{- end }}
export AGENT_LIVE_CODE=$?
exit $(($SERVICE_EXIT_CODE + $BINDINGS_EXIT_CODE + $QUEUES_EXIT_CODE + $AGENT_LIVE_CODE))
