{{- define "util_mysql_delete_alarm_definition_sh_tpl" -}}
#!/bin/bash

export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}  
export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}



/usr/bin/mysql --host={{.Values.monasca_mysql_endpoint_host_internal}} --port={{.Values.monasca_mysql_port_internal}} --database=mon --user=monapi --password={{.Values.monasca_mysql_monapi_password}} --execute="delete from alarm_definition where deleted_at IS NOT NULL;"  > ${STDOUT_LOC} 2> ${STDERR_LOC}
{{ end }}
