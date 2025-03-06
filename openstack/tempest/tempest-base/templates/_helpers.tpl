{{- define "tempest-base.resolve_secret" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str) -}}
        {{"{{"}} resolve "{{ $str }}" {{"}}"}}
    {{- else if (hasPrefix "{{" $str) }}
        {{- $str }}
    {{- else }}
        {{- $str }}
    {{- end }}
{{- end -}}
