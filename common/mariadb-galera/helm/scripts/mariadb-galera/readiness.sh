#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function checkdblogon {
  mysql --protocol=socket --user=root --database=mysql --wait --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.database }} --reconnect --execute="STATUS;" | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
  if [ $? -eq 0 ]; then
    mysql --protocol=socket --user=root --batch --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.database }} --execute="SHOW DATABASES;" | grep --silent 'mysql'
    if [ $? -eq 0 ]; then
      echo 'MariaDB MySQL API usable'
    else
      echo 'MariaDB MySQL API not usable'
      exit 1
    fi
  else
    echo 'MariaDB MySQL API not usable'
    exit 1
  fi
}

function checkgaleraclusterstatus {
  mysql --protocol=socket --user=root --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.database }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_cluster_status';" --batch --skip-column-names | grep --silent 'Primary'
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera node reports a working cluster status'
  else
    echo 'MariaDB Galera node reports a not working cluster status'
    exit 1
  fi
}

function checkgaleranodejoinstatus {
  mysql --protocol=socket --user=root --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.database }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_local_state_comment';" --batch --skip-column-names | grep --silent 'Synced'
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera node is in sync with the cluster'
  else
    echo 'MariaDB Galera node not in sync with the cluster'
    exit 1
  fi
}

function checkgaleranodeconnectstatus {
  mysql --protocol=socket --user=root --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.database }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_connected';" --batch --skip-column-names | grep --silent 'ON'
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera node connected to other cluster nodes'
  else
    echo 'MariaDB Galera node not connected to other cluster nodes'
    exit 1
  fi
}

function checkgaleraready {
  mysql --protocol=socket --user=root --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.database }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_ready';" --batch --skip-column-names | grep --silent 'ON'
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera ready for queries'
  else
    echo 'MariaDB Galera not ready for queries'
    exit 1
  fi
}

function checknoderejectsconnections {
  mysql --protocol=socket --user=root --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.database }} --execute="SHOW VARIABLES LIKE 'wsrep_reject_queries';" --batch --skip-column-names | grep --silent 'NONE'
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera node does accept new client connections'
  else
    echo 'MariaDB Galera node does not accept new client connections'
    exit 1
  fi
}

checkdblogon
checkgaleraclusterstatus
checkgaleranodejoinstatus
checkgaleranodeconnectstatus
checkgaleraready
checknoderejectsconnections
setconfigmap "seqno" $(fetchcurrentseqno) "Update"
setconfigmap "primary" "true" "Update"
