#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

waitfordatabase
loginfo "null" "configuration job started"

{{- /* database configuration */}}
{{- range $dbKey, $dbValue := $.Values.mariadb.databases }}
  {{- if $dbValue.enabled }}
setupdatabase {{ $dbKey | squote }} {{ $dbValue.comment | default "custom DB" | squote }} {{ $dbValue.collationName | default "utf8_general_ci" | squote }} {{ $dbValue.CharacterSetName | default "utf8" | squote }} {{ $dbValue.enabled }} {{ $dbValue.overwrite | default "false" }} {{ $dbValue.deleteIfDisabled | default "false" }}
  {{- end }}
{{- end }}

{{- /* role configuration */}}
{{- range $roleKey, $roleValue := $.Values.mariadb.roles }}
  {{- if $roleValue.enabled }}
    {{- if $roleValue.grant }}
setuprole {{ $roleKey | squote }} {{ $roleValue.privileges | join ", " | squote }} {{ $roleValue.object | squote }} "WITH GRANT OPTION"
    {{- else }}
setuprole {{ $roleKey | squote }} {{ $roleValue.privileges | join ", " | squote }} {{ $roleValue.object | squote }} ""
    {{- end }}
  {{- end }}
{{- end }}

{{- /* user configuration */}}
{{- $usernameEnvVar := "" }}
{{- $passwordEnvVar := "" }}
{{- $userRequired := false }}
{{- range $userKey, $userValue := $.Values.mariadb.users }}
  {{- $requiredUsers := list "root" }}
  {{- if or ($.Values.monitoring.mysqld_exporter.enabled) (and ($.Values.proxy.enabled) (eq $.Values.proxy.type "proxysql")) }}
    {{- $requiredUsers = append $requiredUsers "monitor" }}
    {{- $requiredUsers = $requiredUsers | uniq | compact }}
  {{- end}}
  {{- if or (has $userKey $requiredUsers) $userValue.enabled }}
    {{- range $hostnameKey, $hostnameValue := required (printf "A valid '.hostnames' structure is required for the '%s' user" $userKey) $userValue.hostnames }}
      {{- $usernameEnvVar = "" }}
      {{- $passwordEnvVar = "" }}
      {{- $userRequired = false }}
      {{- range $envKey, $envValue := $.Values.env }}
        {{- if (has "databasecfgjob" $envValue.containerType) }}
          {{- if eq $userValue.secretName $envValue.secretName }}
            {{- $userRequired = true }}
            {{- if hasSuffix "_USERNAME" $envKey }}
              {{- $usernameEnvVar = $envKey }}
            {{- end }}
            {{- if hasSuffix "_PASSWORD" $envKey }}
              {{- $passwordEnvVar = $envKey }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- if $userRequired }}
        {{- if and $usernameEnvVar $passwordEnvVar }}
          {{- if and (eq $usernameEnvVar "MARIADB_ROOT_USERNAME") (or (eq $hostnameValue "127.0.0.1") (eq $hostnameValue "localhost")) }}
            {{- /* do not configure localhost root accounts to not break socket authentication */}}
          {{- else }}
            {{- if $userValue.adminoption }}
setupuser {{ (printf "${%s}" $usernameEnvVar) | quote }} {{ (printf "${%s}" $passwordEnvVar) | quote }} {{ $userValue.defaultrole | squote }} {{ $userValue.maxconnections | int }} {{ $hostnameValue | squote }} {{ $userValue.authplugin | squote }} "WITH ADMIN OPTION"
            {{- else }}
setupuser {{ (printf "${%s}" $usernameEnvVar) | quote }} {{ (printf "${%s}" $passwordEnvVar) | quote }} {{ $userValue.defaultrole | squote }} {{ $userValue.maxconnections | int }} {{ $hostnameValue | squote }} {{ $userValue.authplugin | squote }} " "
            {{- end }}
            {{- if and (hasKey $userValue "additionalroles") (kindIs "slice" $userValue.additionalroles) }}
              {{- range $rolenameKey, $rolenameValue := $userValue.additionalroles }}
                {{- if $userValue.adminoption }}
grantrole {{ $rolenameValue | squote }} {{ $userKey | squote }} {{ $hostnameValue | squote }} "WITH ADMIN OPTION"
                {{- else }}
grantrole {{ $rolenameValue | squote }} {{ $userKey | squote }} {{ $hostnameValue | squote }} " "
                {{- end }}
              {{- end }}
            {{- end }}
setdefaultrole {{ $userValue.defaultrole | squote }} {{ $userKey | squote }} {{ $hostnameValue | squote }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- if not $usernameEnvVar }}
      {{ fail (printf "'_USERNAME' environment variable for the '%s' user is not defined, but required for the MariaDB user setup" $userKey) }}
    {{- end }}
    {{- if not $passwordEnvVar }}
      {{ fail (printf "'_PASSWORD' environment variable for the '%s' user password is not defined, but required for the MariaDB user setup" $userKey) $passwordEnvVar }}
    {{- end }}
  {{- end }}
{{- end }}

listdbandusers

{{- if $.Values.mariadb.asyncReplication.enabled }}
stopasyncreplication
setupasyncreplication
startasyncreplication
checkasyncreplication
{{- else }}
stopasyncreplication
{{- end }}

loginfo "null" "configuration job finished"
