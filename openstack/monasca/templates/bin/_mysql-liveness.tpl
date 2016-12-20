{{- define "mysql_liveness_tpl" -}}
#!/bin/bash

set -e

export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}  
export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}

# check if the user created latest in the schema exists in the db
/usr/bin/mysql -u root -e "SHOW GLOBAL STATUS LIKE 'Innodb_deadlocks'" | grep -w -q "0" > ${STDOUT_LOC} 2> ${STDERR_LOC}
{{ end }}
