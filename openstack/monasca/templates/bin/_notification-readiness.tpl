{{- define "notification_readiness_tpl" -}}
#!/bin/bash

set -e
nc -z zk {{.Values.monasca_zookeeper_port_internal}}
{{ end }}
