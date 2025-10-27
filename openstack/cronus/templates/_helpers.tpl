{{- define "cronus.resolve_secret_urlquery" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" | urlquery {{"}}"}}
    {{- else -}}
        {{ $str }}
    {{- end -}}
{{- end -}}

{{- define "cronus.amqp_url" -}}
{{- $username := include "cronus.resolve_secret_urlquery" .username -}}
{{- $password := include "cronus.resolve_secret_urlquery" .password -}}
{{- $host := .host -}}
amqp://{{- $username -}}:{{- $password -}}@{{- $host -}}/
{{- end}}
