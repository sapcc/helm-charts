#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function waitfordatabase {
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    checkdbk8sservicelogon "true"
    if [ $? -eq 0 ]; then
      break
    else
      loginfo "${FUNCNAME[0]}" "database not yet usable. Will wait ${WAIT_SECONDS}s before retry"
      sleep ${WAIT_SECONDS}
    fi
  done
}

waitfordatabase
loginfo "null" "configuration job started"
{{- if $.Values.monitoring.mysqld_exporter.enabled }}
setupuser "${MARIADB_MONITORING_USER}" "${MARIADB_MONITORING_PASSWORD}" 'mysql_exporter' "${MARIADB_MONITORING_CONNECTION_LIMIT}" '%'
setupuser "${MARIADB_MONITORING_USER}" "${MARIADB_MONITORING_PASSWORD}" 'mysql_exporter' "${MARIADB_MONITORING_CONNECTION_LIMIT}" '127.0.0.1'
setupuser "${MARIADB_MONITORING_USER}" "${MARIADB_MONITORING_PASSWORD}" 'mysql_exporter' "${MARIADB_MONITORING_CONNECTION_LIMIT}" '127.0.0.1' '::1'
{{- end }}

{{- /* Load additional configuration files for MariaDB to be processed by the job container */}}
{{- $mariadbconfigs := $.Files.Get "config/mariadb-galera/values.yaml" | fromYaml }}
{{- range $mariadbconfigKey, $mariadbconfigValue := required "A valid 'configs.' structure is required from config/mariadb-galera/values.yaml" $mariadbconfigs.configs }}
  {{- if $mariadbconfigValue.enabled}}
    {{- $configfile := $.Files.Get (printf "config/mariadb-galera/%s/%s" $mariadbconfigValue.type $mariadbconfigValue.file) | fromYaml }}
    {{- if eq $mariadbconfigValue.type "database" }}
setupdatabase {{ $mariadbconfigValue.name | quote }} {{ $configfile.comment | quote }} {{ $configfile.collationName | quote }} {{ $configfile.CharacterSetName | quote }} {{ $configfile.enabled }} {{ $configfile.overwrite }} {{ $configfile.deleteIfDisabled }}
    {{- else if eq $mariadbconfigValue.type "role" }}
      {{- if $configfile.grant }}
setuprole {{ $mariadbconfigValue.name | quote }} {{ $configfile.privileges | join ", " | quote }} {{ $configfile.object | quote }} "WITH GRANT OPTION"
      {{- else }}
setuprole {{ $mariadbconfigValue.name | quote }} {{ $configfile.privileges | join ", " | quote }} {{ $configfile.object | quote }} ""
      {{- end }}
    {{- else if eq $mariadbconfigValue.type "user" }}
      {{- range $hostnameKey, $hostnameValue := required (printf "A valid 'hostnames.' structure is required in config/mariadb-galera/%s/%s" $mariadbconfigValue.type $mariadbconfigValue.file) $configfile.hostnames }}
        {{- range $envKey, $envValue := $.Values.env }}
          {{- if and (eq $envKey ($configfile.password | trimAll "${}")) ($envValue) }}
setupuser {{ $configfile.username | quote }} {{ $configfile.password | quote }} {{ $configfile.role | quote }} {{ $configfile.maxconnections | quote }} {{ $hostnameValue | quote }}
          {{- else }}
            {{- /* fail (printf "%s environment variable not defined, but required for config/mariadb-galera/%s/%s" ($configfile.password | trimAll "${}" | quote) $mariadbconfigValue.type $mariadbconfigValue.file) */}}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

listdbandusers
loginfo "null" "configuration job finished"
