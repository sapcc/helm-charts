{{- define "filerNameFromHost" -}}
{{- regexSplit "\\.cc" . -1 | first }}
{{- end -}}

{{- define "upper" -}}
{{ . | upper | replace "-" "_" }}
{{- end -}}

{{- define "backendCredentialEnvs" -}}
{{- range .filers }}
- name: {{ .name | include "upper" }}_USERNAME
  valueFrom:
    secretKeyRef:
      name: manila-share-netapp-{{ include "filerNameFromHost" .host }}
      key: username
- name: {{ .name | include "upper" }}_PASSWORD
  valueFrom:
    secretKeyRef:
      name: manila-share-netapp-{{ include "filerNameFromHost" .host }}
      key: password
{{- end -}}
{{- end -}}

{{- define "backendCredentialConf" -}}
{{- range .filers -}}
{{- "\n" }}
[{{ .name }}]
netapp_login=${{ .name | include "upper" }}_USERNAME
netapp_password=${{ .name | include "upper" }}_PASSWORD
{{- end -}}
{{- end -}}
