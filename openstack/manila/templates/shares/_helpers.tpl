{{- define "filerNameFromHost" -}}
{{- regexSplit "\\.cc" . -1 | first }}
{{- end -}}

{{- define "upper" -}}
{{ . | upper | replace "-" "_" }}
{{- end -}}

{{- define "backendCredentialEnvs" -}}
{{- range .filers }}
- name: {{ include "filerNameFromHost" .host | include "upper" }}_USERNAME
  valueFrom:
    secretKeyRef:
      name: manila-share-netapp-{{ include "filerNameFromHost" .host }}
      key: username
- name: {{ include "filerNameFromHost" .host | include "upper" }}_PASSWORD
  valueFrom:
    secretKeyRef:
      name: manila-share-netapp-{{ include "filerNameFromHost" .host }}
      key: password
{{- end -}}
{{- end -}}

{{- define "backendCredentialConf" -}}
{{- range .filers }}
[{{ .name }}]
netapp_login=${{ include "filerNameFromHost" .host | include "upper" }}_USERNAME
netapp_password=${{ include "filerNameFromHost" .host | include "upper" }}_PASSWORD
{{- "\n" }}
{{- end -}}
{{- end -}}
