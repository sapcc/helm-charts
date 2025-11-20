[interconnection]
username = {{ .Values.interconnection.user | include "resolve_secret" }}
password = {{ required "Interconnection password is missing" .Values.interconnection.password | include "resolve_secret" }}
