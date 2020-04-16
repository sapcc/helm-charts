When passed via `helm upgrade --set`, the image tag is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "migration_dashboard_image" -}}
  {{- if typeIs "string" $.Values.migration_dashboard.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .Values.migration_dashboard.image_tag -}}
      {{ $.Values.global.registryAlternateRegion }}/image-migration-dashboard:{{$.Values.migration_dashboard.image_tag | printf "%0.f"}}
    {{- else -}}
      {{ $.Values.global.registryAlternateRegion }}/image-migration-dashboard:{{$.Values.migration_dashboard.image_tag}}
    {{- end -}}
  {{- end -}}
{{- end -}}
