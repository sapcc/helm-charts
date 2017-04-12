When passed via `helm upgrade --set`, the image tag is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "limes_image" -}}
{{- if eq $.Values.limes.image_tag "DEFINED_BY_PIPELINE" -}}
{{ required "This release should be installed by the deployment pipeline!" "" }}
{{- if typeIs "float64" .Values.limes.image_tag -}}
{{$.Values.limes.image}}:{{$.Values.limes.image_tag | printf "%0.f"}}
{{- else -}}
{{$.Values.limes.image}}:{{$.Values.limes.image_tag}}
{{- end -}}
{{- end -}}
