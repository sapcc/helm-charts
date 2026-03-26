{{/*
Merge extension values with smart image reference handling.
Applies fallback logic for image references while preserving all other values.

Usage:
  # For extension.values (automatically picks up root-level image/images/imageVectorOverwrite)
  {{ include "cc-gardener.extension.mergeValues" (dict "values" .values "extensionContext" . "fallbackTag" .version) | nindent 8 }}

  # For runtimeClusterValues with cascading fallback from parent values
  {{ include "cc-gardener.extension.mergeValues" (dict "values" .runtimeClusterValues "parentValues" .values "fallbackTag" .version) | nindent 8 }}

Parameters:
  - values: The extension values dict (can be nil)
  - parentValues: Optional parent values dict for cascading fallback (for runtimeClusterValues)
  - extensionContext: Optional full extension context (.) to auto-detect root-level image/images/imageVectorOverwrite
  - fallbackTag: The tag to use if not specified in values (typically .version)

Priority for image references:
  1. image.ref or imageRef (complete reference)
  2. image.repository + image.tag
  3. Fallback chain: values.image → parentValues.image → extensionContext.image → fallbackTag

If only repository is specified, tag defaults via fallback chain.
All other values pass through unchanged.
*/}}
{{- define "cc-gardener.extension.mergeValues" -}}
{{- $values := .values | default dict -}}
{{- $parentValues := .parentValues | default dict -}}
{{- $extensionContext := .extensionContext | default dict -}}
{{- $fallbackTag := .fallbackTag | default "" -}}
{{- $result := dict -}}

{{- /* First, copy root-level image/images/imageVectorOverwrite from extensionContext if present */ -}}
{{- if $extensionContext -}}
  {{- if and (hasKey $extensionContext "image") (not (hasKey $values "image")) -}}
    {{- $_ := set $result "image" $extensionContext.image -}}
  {{- end -}}
  {{- if and (hasKey $extensionContext "images") (not (hasKey $values "images")) -}}
    {{- $_ := set $result "images" $extensionContext.images -}}
  {{- end -}}
  {{- if and (hasKey $extensionContext "imageVectorOverwrite") (not (hasKey $values "imageVectorOverwrite")) -}}
    {{- $_ := set $result "imageVectorOverwrite" $extensionContext.imageVectorOverwrite -}}
  {{- end -}}
{{- end -}}

{{- /* Copy all values (overrides extensionContext defaults) */ -}}
{{- range $key, $val := $values -}}
  {{- $_ := set $result $key $val -}}
{{- end -}}

{{- /* Determine fallbacks from parent values */ -}}
{{- $parentTag := "" -}}
{{- $parentRepo := "" -}}
{{- if $parentValues -}}
  {{- if hasKey $parentValues "image" -}}
    {{- if kindIs "string" $parentValues.image -}}
      {{- $parentTag = $parentValues.image -}}
    {{- else if kindIs "map" $parentValues.image -}}
      {{- if hasKey $parentValues.image "tag" -}}
        {{- $parentTag = $parentValues.image.tag -}}
      {{- end -}}
      {{- if hasKey $parentValues.image "repository" -}}
        {{- $parentRepo = $parentValues.image.repository -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- /* Smart handling of image references */ -}}
{{- if hasKey $values "image" -}}
  {{- if kindIs "string" $values.image -}}
    {{- /* image: "repo:tag" - keep as-is */ -}}
    {{- $_ := set $result "image" $values.image -}}
  {{- else if kindIs "map" $values.image -}}
    {{- $imageDict := dict -}}

    {{- /* Repository with cascading fallback */ -}}
    {{- if hasKey $values.image "repository" -}}
      {{- $_ := set $imageDict "repository" $values.image.repository -}}
    {{- else if $parentRepo -}}
      {{- $_ := set $imageDict "repository" $parentRepo -}}
    {{- end -}}

    {{- /* Tag with cascading fallback */ -}}
    {{- if hasKey $values.image "tag" -}}
      {{- $_ := set $imageDict "tag" $values.image.tag -}}
    {{- else if $parentTag -}}
      {{- $_ := set $imageDict "tag" $parentTag -}}
    {{- else if $fallbackTag -}}
      {{- $_ := set $imageDict "tag" $fallbackTag -}}
    {{- end -}}

    {{- /* Copy other image properties (pullPolicy, etc) */ -}}
    {{- range $key, $val := $values.image -}}
      {{- if and (ne $key "repository") (ne $key "tag") -}}
        {{- $_ := set $imageDict $key $val -}}
      {{- end -}}
    {{- end -}}

    {{- /* Only set image if it has content */ -}}
    {{- if $imageDict -}}
      {{- $_ := set $result "image" $imageDict -}}
    {{- end -}}
  {{- end -}}
{{- else if or $parentRepo $parentTag $fallbackTag -}}
  {{- /* No image in values, create from fallbacks if available */ -}}
  {{- $imageDict := dict -}}
  {{- if $parentRepo -}}
    {{- $_ := set $imageDict "repository" $parentRepo -}}
  {{- end -}}
  {{- if $parentTag -}}
    {{- $_ := set $imageDict "tag" $parentTag -}}
  {{- else if $fallbackTag -}}
    {{- $_ := set $imageDict "tag" $fallbackTag -}}
  {{- end -}}
  {{- if or $parentRepo $parentTag $fallbackTag -}}
    {{- $_ := set $result "image" $imageDict -}}
  {{- end -}}
{{- end -}}

{{- /* Handle images (array or dict of multiple image references) */ -}}
{{- if hasKey $values "images" -}}
  {{- if kindIs "slice" $values.images -}}
    {{- /* images as array */ -}}
    {{- $imagesArray := list -}}
    {{- range $values.images -}}
      {{- $imgDict := dict -}}

      {{- /* Copy name */ -}}
      {{- if hasKey . "name" -}}
        {{- $_ := set $imgDict "name" .name -}}
      {{- end -}}

      {{- /* Repository + Tag with fallback */ -}}
      {{- if hasKey . "repository" -}}
        {{- $_ := set $imgDict "repository" .repository -}}
      {{- end -}}

      {{- if hasKey . "tag" -}}
        {{- $_ := set $imgDict "tag" .tag -}}
      {{- else if $fallbackTag -}}
        {{- $_ := set $imgDict "tag" $fallbackTag -}}
      {{- end -}}

      {{- /* Copy other properties */ -}}
      {{- range $key, $val := . -}}
        {{- if and (ne $key "name") (ne $key "repository") (ne $key "tag") -}}
          {{- $_ := set $imgDict $key $val -}}
        {{- end -}}
      {{- end -}}

      {{- $imagesArray = append $imagesArray $imgDict -}}
    {{- end -}}
    {{- $_ := set $result "images" $imagesArray -}}
  {{- else if kindIs "map" $values.images -}}
    {{- /* images as dict */ -}}
    {{- $imagesDict := dict -}}
    {{- range $name, $img := $values.images -}}
      {{- $imgDict := dict -}}

      {{- /* Repository + Tag with fallback */ -}}
      {{- if hasKey $img "repository" -}}
        {{- $_ := set $imgDict "repository" $img.repository -}}
      {{- end -}}

      {{- if hasKey $img "tag" -}}
        {{- $_ := set $imgDict "tag" $img.tag -}}
      {{- else if $fallbackTag -}}
        {{- $_ := set $imgDict "tag" $fallbackTag -}}
      {{- end -}}

      {{- /* Copy other properties */ -}}
      {{- range $key, $val := $img -}}
        {{- if and (ne $key "repository") (ne $key "tag") -}}
          {{- $_ := set $imgDict $key $val -}}
        {{- end -}}
      {{- end -}}

      {{- $_ := set $imagesDict $name $imgDict -}}
    {{- end -}}
    {{- $_ := set $result "images" $imagesDict -}}
  {{- end -}}
{{- end -}}

{{- if $result -}}
{{- /* Handle imageVectorOverwrite specially to always output with pipe style */ -}}
{{- $imageVectorOverwrite := index $result "imageVectorOverwrite" | default nil -}}
{{- if $imageVectorOverwrite -}}
  {{- $_ := unset $result "imageVectorOverwrite" -}}
{{- end -}}
{{- /* Output all regular fields */ -}}
{{- if $result -}}
{{ toYaml $result -}}
{{- end -}}
{{- /* Output imageVectorOverwrite with pipe style (convert dict to string if needed) */ -}}
{{- if $imageVectorOverwrite }}
imageVectorOverwrite: |
{{- if kindIs "string" $imageVectorOverwrite -}}
{{ $imageVectorOverwrite | trim | nindent 2 -}}
{{- else -}}
{{ toYaml $imageVectorOverwrite | nindent 2 -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Render OCI repository reference for helm charts with smart fallback logic for tag.

Usage:
  {{ include "cc-gardener.extension.ociRepository" (dict "ociRepository" .helm.ociRepository "fallbackTag" .version) | indent 10 }}

Parameters:
  - ociRepository: The ociRepository dict
  - fallbackTag: The tag to use if not specified (typically .version)

Priority for references:
  1. ref (complete OCI reference including tag) - if defined, output ONLY this field
  2. digest (SHA256 digest) - output with repository if both are present
  3. repository + tag - output as separate fields (tag uses fallbackTag if not specified)

Explicitly unsets conflicting fields to prevent Helm merge conflicts during upgrades:
- When using ref: unsets repository and tag
- When using repository/tag: unsets ref
*/}}
{{- define "cc-gardener.extension.ociRepository" -}}
{{- $ociRepo := .ociRepository | default dict -}}
{{- $fallbackTag := .fallbackTag | default "" -}}
{{- /* Priority 1: ref for helm chart OCI repositories */ -}}
{{- if hasKey $ociRepo "ref" -}}
ref: {{ $ociRepo.ref }}
repository: null
tag: null
{{- else -}}
{{- /* Priority 2: repository/tag - unset ref */ -}}
ref: null
{{- /* Digest (can coexist with repository) */ -}}
{{- if hasKey $ociRepo "digest" -}}
digest: {{ $ociRepo.digest }}
{{- end -}}
{{- /* Repository and Tag as separate fields */ -}}
{{- if hasKey $ociRepo "repository" }}
repository: {{ $ociRepo.repository }}
{{- end -}}
{{- if hasKey $ociRepo "tag" }}
tag: {{ $ociRepo.tag }}
{{- else if $fallbackTag }}
tag: {{ $fallbackTag }}
{{- end -}}
{{- end -}}
{{- /* pullSecretRef if present */ -}}
{{- if hasKey $ociRepo "pullSecretRef" }}
pullSecretRef:
{{ toYaml $ociRepo.pullSecretRef | nindent 2 }}
{{- end -}}
{{- end -}}
