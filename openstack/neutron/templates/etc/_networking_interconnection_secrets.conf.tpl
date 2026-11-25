[interconnection]
{{- $name := required "No defaultUser defined in interconnection" .Values.interconnection.defaultUser }}
{{- $creds := required (printf "No user '%s' in interconnection.users" $name) (index .Values.interconnection.users $name) }}
username = {{  required (printf "No username for '%s' in interconnection.users" $name) $creds.username | include "resolve_secret" }}
password = {{  required (printf "No password for '%s' in interconnection.users" $name) $creds.password | include "resolve_secret" }}
