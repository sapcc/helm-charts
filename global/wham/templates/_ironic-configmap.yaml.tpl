{{- define "ironic_configmap" }}
    {{- $region := index . 1 }}
    {{- with index . 0 }}
    {{- $region_ := $region | replace "-" "_"}}
{{ printf "%s:" $region }}
  user:  {{ (index .Values $region_ "user" ) }}
  password: {{ (index .Values $region_ "password" ) }}
  auth_url: {{ printf "https://identity-3.%s.cloud.sap/v3" $region }}
{{- end }}
{{- end }}