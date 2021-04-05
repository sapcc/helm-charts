{{- define "migration_dashboard_image" -}}
  {{- if contains "DEFINED" $.Values.migration_dashboard.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registryAlternateRegion }}/image-migration-dashboard:{{$.Values.migration_dashboard.image_tag}}
  {{- end -}}
{{- end -}}
