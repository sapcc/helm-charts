[interconnection]
region_name = {{ required "Interconnection service_region_name is missing" .Values.interconnection.service_region_name }}
username = {{ required "Interconnection service_user is missing" .Values.interconnection.service_user }}
password = {{ required "Interconnection service_password is missing" .Values.interconnection.service_password }}
