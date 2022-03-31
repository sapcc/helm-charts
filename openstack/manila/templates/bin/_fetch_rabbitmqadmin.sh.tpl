#!/bin/sh

set -e

wget http://manila-rabbitmq:15672/cli/rabbitmqadmin
chmod +x rabbitmqadmin
mv rabbitmqadmin /shared
{{- if not .Values.api_backdoor }}
# create file which creates a guru mediation report when touched
touch /shared/guru
{{- end }}
