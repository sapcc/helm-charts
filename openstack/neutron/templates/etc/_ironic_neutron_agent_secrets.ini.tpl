[ironic]
{{ $user := print (coalesce .Values.global.ironicServiceUser .Values.global.ironic_service_user "ironic") (default "" .Values.global.user_suffix) }}

# keystoneV3 values
username = {{ $user }}
password = {{ required ".Values.global.ironic_service_password is missing" .Values.global.ironic_service_password }}
