[interconnection]
username = {{ .Values.interconnection.user }}
password = {{ required "Interconnection password is missing" .Values.interconnection.password }}
