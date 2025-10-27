#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /usr/bin/common-functions.sh

declare mysqlOpts
mysqlOpts="--protocol=tcp --host={{ include "fullName" . }} --user=root --password=${MYSQL_ROOT_PASSWORD} --database=mysql --wait --connect-timeout=5 --reconnect --batch"

function listTables {
  mysql ${mysqlOpts} --skip-column-names --execute="SELECT CONCAT('\`',table_schema,'\`.\`',table_name,'\`') FROM information_schema.tables WHERE table_schema NOT IN ('information_schema','performance_schema','mysql','sys','innodb') AND engine IS NOT NULL;"
  if [ "$?" -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "table query failed"
    exit 1
  fi
}

function analyzeTable {
  local tblName MYSQL_RESPONSE MYSQL_STATUS MYSQL_QUERY_STATUS
  tblName=$1

  if [[ -z "$tblName" ]]; then
    logerror "${FUNCNAME[0]}" "missing table name"
    exit 1
  else
    loginfo "${FUNCNAME[0]}" "analyze table ${tblName}"
    MYSQL_RESPONSE=$(mysql ${mysqlOpts} --execute="ANALYZE TABLE ${tblName} PERSISTENT FOR ALL;")
    MYSQL_STATUS=$?
    MYSQL_QUERY_STATUS=$(echo "${MYSQL_RESPONSE}" | grep "Error" | wc -l)
    {{- if $.Values.job.maintenance.function.analyzeTable.verbose }}
    echo "${MYSQL_RESPONSE}"
    {{- end }}

    if [ "${MYSQL_STATUS}" -ne 0 ] || [ "${MYSQL_QUERY_STATUS}" -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "analyze table ${tblName} failed"
      echo "${MYSQL_RESPONSE}"
      exit 1
    else
      loginfo "${FUNCNAME[0]}" "analyze table ${tblName} done"
    fi
  fi
}
{{- if $.Values.job.maintenance.function.analyzeTable.allTables }}
for table in $(listTables);
do
  analyzeTable "${table}"
done
{{- else }}
  {{ range $.Values.job.maintenance.function.analyzeTable.tables }}
analyzeTable {{ . | quote }}
  {{- end }}
{{- end }}