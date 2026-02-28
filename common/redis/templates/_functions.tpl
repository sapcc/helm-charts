{{- define "redis.shared-app-images.tag" -}}
  {{- $ctx       := index . 0 -}}
  {{- $repo      := index . 1 -}}
  {{- $version   := index . 2 -}}

  {{- $all_tags := $ctx.Files.Get "files/tags.json" | required "files/tags.json not found" | fromJson -}}
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
