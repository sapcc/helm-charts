#!/bin/bash

if [[ $1 == '-h' || $1 == '--help' ]]; then
	echo "Usage: $0 <user> <pass> <log_file>"
	exit
fi

if [ -f /tmp/recovery-case ] || [ -f '/var/lib/mysql/sleep-forever' ]; then
	exit 0
fi

if [[ -f '/var/lib/mysql/sst_in_progress' ]] || [[ -f '/var/lib/mysql/wsrep_recovery_verbose.log' ]]; then
	exit 0
fi

{ set +x; } 2>/dev/null
MYSQL_USERNAME="monitor"
MYSQL_PASSWORD="${MONITOR_PASSWORD}"
#Timeout exists for instances where mysqld may be hung
TIMEOUT=3

MYSQL_CMDLINE="/usr/bin/timeout $TIMEOUT mysql -u ${MYSQL_USERNAME} -nNE --connect-timeout=$TIMEOUT"

STATUS=$(MYSQL_PWD="${MYSQL_PASSWORD}" $MYSQL_CMDLINE --init-command="SET SESSION wsrep_sync_wait=0;" -e "SHOW GLOBAL STATUS LIKE 'wsrep_cluster_status';" | sed -n -e '3p')
set -x

if [[ -n ${STATUS} && ${STATUS} == 'Primary' ]]; then
	exit 0
fi

exit 1
