{{- define "gatekeeper-policies.get-library-code" -}}
  {{- $ctx  := index . 0 -}}
  {{- $name := index . 1 -}}

  {{- $this_chart := index $ctx.Subcharts "gatekeeper-policies" | required "subchart \"gatekeeper-policies\" may not be declared with an alias" -}}
  {{- $this_chart.Files.Get (printf "files/lib/%s.rego" $name) | trim -}}
{{- end -}}

{{- define "gatekeeper-policies.get-policy-code" -}}
  {{- $ctx  := index . 0 -}}
  {{- $kind := index . 1 -}}

  {{- $this_chart := index $ctx.Subcharts "gatekeeper-policies" | required "subchart \"gatekeeper-policies\" may not be declared with an alias" -}}
  {{- $this_chart.Files.Get (printf "files/policies/%s.rego" $kind) | trim -}}
{{- end -}}

{{- define "gatekeeper-policies.get-param-schema" -}}
  {{- $ctx  := index . 0 -}}
  {{- $kind := index . 1 -}}

  {{- $this_chart := index $ctx.Subcharts "gatekeeper-policies" | required "subchart \"gatekeeper-policies\" may not be declared with an alias" -}}
  {{- $decl := $this_chart.Files.Get (printf "files/parameters/%s.yaml" $kind) | fromYaml -}}
  {{- if hasKey $decl "schema" -}}
    {{- index $decl "schema" | toYaml | trim -}}
  {{- end -}}
{{- end -}}

{{- define "gatekeeper-policies.render-constraint-template" -}}
  {{- $ctx  := index . 0 -}}
  {{- $kind := index . 1 -}}

  {{- $param_schema := tuple $ctx $kind | include "gatekeeper-policies.get-param-schema" -}}
  {{- $policy_code  := tuple $ctx $kind | include "gatekeeper-policies.get-policy-code" -}}
  {{- $imports := regexFindAll "(?m)^import data\\.lib\\.\\w*" $policy_code -1 -}}

apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: {{ lower $kind }}
spec:
  crd:
    spec:
      names:
        kind: {{ $kind }}
      {{- if $param_schema }}
      validation:
        openAPIV3Schema:
          {{ $param_schema | nindent 10 }}
      {{- end }}

  targets:
    - target: admission.k8s.gatekeeper.sh
      code:
        - engine: Rego
          source:
            version: "v1"
            {{- if $imports }}
            libs:
              {{- range $import := $imports }}
              {{- $lib_name := $import | trimPrefix "import data.lib." }}
              - {{ tuple $ctx $lib_name | include "gatekeeper-policies.get-library-code" | quote }}
              {{- end }}
            {{- end }}
            rego: {{ quote $policy_code }}
{{- end -}}
