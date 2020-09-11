{{- define "octavia_worker_change_pw" -}}
{{- $envAll := index . 0 -}}
{{- $loadBalancer := index . 1 -}}
#!/bin/sh

{{- range $loadBalancer.hosts}}
echo "Checking {{.}}"

# Check legacy password valid
curl -skf -u admin:{{$envAll.Values.global.legacy_f5_password}} -H "Content-Type: application/json" https://{{.}}/mgmt/tm/auth/user/admin
rc=$?

if [[ $rc != 1 ]]
then
    echo "Legacy password still valid, changing to derived one"
    curl -sk -u admin:{{$envAll.Values.global.legacy_f5_password}} -H "Content-Type: application/json" -X PATCH https://{{.}}/mgmt/tm/auth/user/admin -d '{ "password": {{ tuple $envAll "admin" . "long" | include "utils.password_for_fixed_user_and_host" | quote }} }'
fi
{{- end }}
{{- end }}
