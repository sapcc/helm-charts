{{/* This generates annotations that the DOOP dashboard reads to link back to the source code of constraint templates and constraints. */}}
{{- define "sources" }}
template-source:   'https://github.com/sapcc/helm-charts/tree/master/system/gatekeeper/templates/constrainttemplate-{{ index . 0 }}.yaml'
constraint-source: 'https://github.com/sapcc/helm-charts/tree/master/system/gatekeeper/templates/constraint-{{ index . 1 }}.yaml'
{{- end }}

{{/* This generates an annotation containing the constraint's docstring. */}}
{{- define "docstring" }}
docstring: {{ (index . 0).Files.Get (printf "files/%s.md" (index . 1)) | toJson }}
{{- end }}

{{- define "doop_image_checker_url" -}}
{{ $.Values.doop_image_checker_url | replace "$NAMESPACE" $.Release.Namespace }}
{{- end -}}

{{- define "helm_manifest_parser_url" -}}
{{ $.Values.helm_manifest_parser_url | replace "$NAMESPACE" $.Release.Namespace }}
{{- end -}}
