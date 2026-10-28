{{/*
Redirect annotation used when redirect.enabled is true (Plutono sunset).
302 (temporal-redirect) for the initial rollout, 301 (permanent-redirect) once stable.
Both annotation prefixes are set, the same as the oauth annotations in this chart: the SCI
ingress-nginx controllers run with --annotations-prefix=ingress.kubernetes.io and ignore
nginx.ingress.kubernetes.io/*.
Usage: include "plutono.redirect.annotation" (dict "redirect" .Values.redirect "target" "https://...")
*/}}
{{- define "plutono.redirect.annotation" -}}
{{- $target := required "redirect target missing (.Values.redirect.target / .Values.redirect.globalTarget)" .target | trimSuffix "/" -}}
{{- $name := "" -}}
{{- if eq (int .redirect.code) 301 -}}
{{- $name = "permanent-redirect" -}}
{{- else if eq (int .redirect.code) 302 -}}
{{- $name = "temporal-redirect" -}}
{{- else -}}
{{- fail "redirect.code must be 301 or 302" -}}
{{- end -}}
ingress.kubernetes.io/{{ $name }}: {{ $target | quote }}
nginx.ingress.kubernetes.io/{{ $name }}: {{ $target | quote }}
{{- end -}}
