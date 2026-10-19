{{- define "shared-app-images.tag" -}}
  {{- $ctx       := index . 0 -}}
  {{- $repo      := index . 1 -}}
  {{- $version   := index . 2 -}}

  {{- $this_chart := index $ctx.Subcharts "shared-app-images-tags" | required "subchart \"shared-app-images-tags\" may not be declared with an alias" -}}
  {{- $all_tags   := $this_chart.Files.Get "files/tags.json" | fromJson -}}
  {{- $repo_tags  := index $all_tags $repo | required (printf "unknown repo: %q" (printf "shared-app-images/%s" $repo)) -}}
  {{- index $repo_tags $version | required (printf "no such version in repo: %q (version may have been removed because of EOL)" (printf "shared-app-images/%s:%s" $repo $version)) -}}
{{- end -}}

{{- define "shared-app-images.ref" -}}
  {{- $ctx     := index . 0 -}}
  {{- $repo    := index . 1 -}}
  {{- $version := index . 2 -}}

  {{- $tag      := include "shared-app-images.tag" (tuple $ctx $repo $version) -}}
  {{- $registry := $ctx.Values.global.registry | required "missing value for .Values.global.registry" -}}
  {{- printf "%s/shared-app-images/%s:%s" $registry $repo $tag -}}
{{- end -}}

{{- define "shared-app-images.ref_using_alternate" -}}
  {{- $ctx     := index . 0 -}}
  {{- $repo    := index . 1 -}}
  {{- $version := index . 2 -}}

  {{- $tag      := include "shared-app-images.tag" (tuple $ctx $repo $version) -}}
  {{- $registry := $ctx.Values.global.registryAlternateRegion | required "missing value for .Values.global.registryAlternateRegion" -}}
  {{- printf "%s/shared-app-images/%s:%s" $registry $repo $tag -}}
{{- end -}}
