{{- define "cell0_db_path" -}}
postgresql+psycopg2://{{.Values.cell0dbUser}}:{{.Values.cell0dbPassword | default (tuple . .Values.cell0dbUser | include "postgres.password_for_user") | urlquery }}@{{.Chart.Name}}-postgresql.{{include "svc_fqdn" .}}:5432/{{.Values.cell0dbName}}
{{- end -}}

{{- define "cell2_db_path" -}}
postgresql+psycopg2://{{.Values.cell2dbUser}}:{{ .Values.cell2dbPassword | default (tuple . .Values.cell2dbUser | include "postgres.password_for_user" | urlquery ) }}@{{.Chart.Name}}-{{.Values.cell2.name}}-postgresql.{{include "svc_fqdn" .}}:5432/{{.Values.cell2dbName}}
{{- end -}}

{{- define "cell2_transport_url" -}}
rabbit://{{ default "" .Values.global.user_suffix | print .Values.rabbitmq_cell2.users.default.user }}:{{ .Values.rabbitmq_cell2.users.default.password | default (tuple . .Values.rabbitmq_cell2.users.default.user | include "rabbitmq.password_for_user")  | urlquery}}@{{.Chart.Name}}-{{.Values.cell2.name}}-rabbitmq.{{include "svc_fqdn" .}}:{{ .Values.rabbitmq_cell2.port | default 5672 }}{{ .Values.rabbitmq_cell2.virtual_host | default "/" }}
{{- end -}}


{{- define "container_image_nova" -}}
  {{- $name := index . 1 -}}
  {{- with index . 0 -}}
    {{- $version_name := printf "imageVersionNova%s" ($name | lower | replace "-" " " | title | nospace) -}}
    {{- $image_name := ( .Values.loci.nova | ternary .Values.imageNameNova (printf "ubuntu-source-nova-%s" ($name | lower)) ) -}}

    {{.Values.global.imageRegistry}}/{{.Values.global.image_namespace}}/{{$image_name}}:{{index .Values $version_name | default .Values.imageVersionNova | default .Values.imageVersion | required "Please set nova.imageVersionNova or similar" }}
 
  {{- end -}}
{{- end -}}

{{- define "container_image_openvswitch" -}}
  {{- $name := index . 1 -}}
  {{- with index . 0 -}}
    {{- $version_name := printf "imageVersionOpenvswitch%s" ($name | lower | replace "-" " " | title | nospace) -}}
    {{- $image_name := ( .Values.loci.nova | ternary .Values.imageNameNova (printf "ubuntu-source-openvswitch-%s" ($name | lower)) ) -}}

    {{.Values.global.imageRegistry}}/{{.Values.global.image_namespace}}/{{$image_name}}:{{index .Values $version_name | default .Values.imageVersionOpenvswitch | default .Values.imageVersionNova | default .Values.imageVersion | required "Please set imageVersionOpenvswitch or similar" }}

  {{- end -}}
{{- end -}}


{{- define "container_image_neutron" -}}
  {{- $name := index . 1 -}}
  {{- with index . 0 -}}
    {{- $version_name := printf "imageVersionNeutron%s" ($name | lower | replace "-" " " | title | nospace) -}}
    {{- $image_name := .Values.imageNameNeutron -}}

    {{.Values.global.imageRegistry}}/{{.Values.global.image_namespace}}/{{$image_name}}:{{index .Values $version_name | default .Values.imageVersionNeutron | required "Please set imageVersionNeutron or similar" }}

  {{- end -}}
{{- end -}}

