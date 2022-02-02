[interconnection]
region_name = {{ .Values.global.region }}
username = {{ .Values.global.interconnection_user }}
password = {{ required "Interconnection service_password is missing" .Values.interconnection.service_password }}
