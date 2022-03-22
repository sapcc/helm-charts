{{- define "bastion_image" -}}
  {{- if contains "DEFINED" $.Values.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registryAlternateRegion }}/bastion:{{$.Values.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "bastion_global_image" -}}
  {{- if contains "DEFINED" $.Values.bastion_global_image -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registryAlternateRegion }}/bastion-global:{{$.Values.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "bastion_environment" }}
- name:  debug
  value: 'false'
- name:  config-path
  value: '/etc/config/bastion.conf'
{{- end -}}

{{- define "db_host" -}}
    keystone-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}