{{- define "redis.shared-app-images.tag" -}}
  {{- $ctx       := index . 0 -}}
  {{- $repo      := index . 1 -}}
  {{- $version   := index . 2 -}}

  {{- $all_tags := include "redis.tags_json" $ctx | fromJson -}}
  {{- $repo_tags  := index $all_tags $repo | required (printf "unknown repo: %q" (printf "shared-app-images/%s" $repo)) -}}
  {{- index $repo_tags $version | required (printf "no such version in repo: %q" (printf "shared-app-images/%s:%s" $repo $version)) -}}
{{- end -}}

{{- define "redis.shared-app-images.ref" -}}
  {{- $ctx     := index . 0 -}}
  {{- $repo    := index . 1 -}}
  {{- $version := index . 2 -}}

  {{- $tag      := include "redis.shared-app-images.tag" (tuple $ctx $repo $version) -}}
  {{- $registry := "" -}}
  {{- if $ctx.Values.useAlternateRegion }}
    {{- $registry = $ctx.Values.global.registryAlternateRegion | required "missing value for .Values.global.registryAlternateRegion" -}}
  {{- else }}
    {{- $registry = $ctx.Values.global.registry | required "missing value for .Values.global.registry" -}}
  {{- end }}
  {{- printf "%s/shared-app-images/%s:%s" $registry $repo $tag -}}
{{- end -}}

{{- define "redis.tags_json" -}}
{{/* Do not change these marker comments! They are required for the automation that updates this data. */}}
{{/* -----BEGIN TAGS_JSON PAYLOAD----- */}}
{
  "alpine-kubectl": {
    "latest": "latest-20260415235401"
  },
  "alpine-valkey": {
    "9.0": "9.0-20260511154107"
  },
  "redis-exporter": {
    "latest": "1.83.0-20260507212050"
  }
}
{{/* -----END TAGS_JSON PAYLOAD----- */}}
{{- end -}}
