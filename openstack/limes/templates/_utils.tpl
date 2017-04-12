When passed via `helm upgrade --set`, the image tag is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "limes_image" -}}
  {{- if typeIs "string" $.Values.limes.image_tag -}}
    { error: "This release should be installed by the deployment pipeline!" }
  {{- else -}}
    {{- if typeIs "float64" .Values.limes.image_tag -}}
      {{$.Values.limes.image}}:{{$.Values.limes.image_tag | printf "%0.f"}}
    {{- else -}}
      {{$.Values.limes.image}}:{{$.Values.limes.image_tag}}
    {{- end -}}
  {{- end -}}
{{- end -}}

TODO: After having upgraded to Helm 2.3, use the "required" function in line 5 instead of generating a syntax error.
