{{- define "rabbitmq_user" -}}
  {{.Values.rabbitmq.users.default.user}}
{{- end -}}

{{- define "rabbitmq_password" -}}
  {{ .Values.rabbitmq.users.default.password | default (tuple . .Values.rabbitmq.users.default.user | include "rabbitmq.password_for_user")}}
{{- end -}}

{{- define "cell0_db_path" -}}
{{.Values.cell0dbUser}}:{{.Values.cell0dbPassword | default .Values.apidbPassword | urlquery}}@{{.Chart.Name}}-postgresql.{{include "svc_fqdn" .}}:5432/{{.Values.cell0dbName}}
{{- end -}}

{{- define "rabbit_url" -}}
  {{- $rabbitmq_host := printf "nova-rabbitmq.%s" ( include "svc_fqdn" . ) -}}
  rabbit://:{{ include "rabbitmq_password" . | urlquery}}@{{ $rabbitmq_host }}:5672/
{{- end -}}

{{- define "container_image_nova" -}}
  {{- $name := index . 1 -}}
  {{- with index . 0 -}}
    {{- $version_name := printf "imageVersionNova%s" ($name | lower | replace "-" " " | title | nospace) -}}
    {{- $image_name := ( .Values.loci | ternary .Values.imageNameNova (printf "ubuntu-source-nova-%s" ($name | lower)) ) -}}

    {{.Values.global.imageRegistry}}/{{.Values.global.image_namespace}}/{{$image_name}}:{{index .Values $version_name | default .Values.imageVersionNova | required "Please set nova.imageVersionNova or similar" }}
 
  {{- end -}}
{{- end -}}

{{- define "container_image_neutron" -}}
  {{- $name := index . 1 -}}
  {{- with index . 0 -}}
    {{- $version_name := printf "imageVersionNeutron%s" ($name | lower | replace "-" " " | title | nospace) -}}
    {{- $image_name := ( .Values.loci | ternary .Values.imageNameNeutron (printf "ubuntu-source-neutron-%s" ($name | lower)) ) -}}

    {{.Values.global.imageRegistry}}/{{.Values.global.image_namespace}}/{{$image_name}}:{{index .Values $version_name | default .Values.imageVersionNeutron | required "Please set imageVersionNeutron or similar" }}

  {{- end -}}
{{- end -}}