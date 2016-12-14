{{- define "rabbitmq_stop_tpl" -}}
#!/bin/bash

echo "stopping rabbitmq"
/etc/init.d/rabbitmq-server stop
{{- end -}}
