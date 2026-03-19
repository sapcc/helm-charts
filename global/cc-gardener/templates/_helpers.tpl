{{/*
Merge extension values with smart image reference handling.
Applies fallback logic for image references while preserving all other values.

Usage:
  # Simple case with just fallbackTag
  {{ include "cc-gardener.extension.mergeValues" (dict "values" .values "fallbackTag" .version) | nindent 8 }}

  # With cascading fallback from parent values (for runtimeClusterValues)
  {{ include "cc-gardener.extension.mergeValues" (dict "values" .runtimeClusterValues "parentValues" .values "fallbackTag" .version) | nindent 8 }}

Parameters:
  - values: The extension values dict (can be nil)
  - parentValues: Optional parent values dict for cascading fallback (for runtimeClusterValues)
  - fallbackTag: The tag to use if not specified in values (typically .version)

Priority for image references:
  1. image.ref or imageRef (complete reference)
  2. image.repository + image.tag
  3. Fallback chain: values.image → parentValues.image → fallbackTag

If only repository is specified, tag defaults via fallback chain.
All other values pass through unchanged.
*/}}
{{- define "cc-gardener.extension.mergeValues" -}}
{{- $values := .values | default dict -}}
{{- $parentValues := .parentValues | default dict -}}
{{- $fallbackTag := .fallbackTag | default "" -}}
{{- $result := dict -}}

{{- /* Copy all values first */ -}}
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

    {{- /* Priority 1: Complete reference (ref/imageRef) */ -}}
    {{- if hasKey $values.image "ref" -}}
      {{- $_ := set $imageDict "ref" $values.image.ref -}}
    {{- else if hasKey $values.image "imageRef" -}}
      {{- $_ := set $imageDict "imageRef" $values.image.imageRef -}}
    {{- else -}}
      {{- /* Priority 2: Repository with cascading fallback */ -}}
      {{- if hasKey $values.image "repository" -}}
        {{- $_ := set $imageDict "repository" $values.image.repository -}}
      {{- else if $parentRepo -}}
        {{- $_ := set $imageDict "repository" $parentRepo -}}
      {{- end -}}

      {{- /* Priority 3: Tag with cascading fallback */ -}}
      {{- if hasKey $values.image "tag" -}}
        {{- $_ := set $imageDict "tag" $values.image.tag -}}
      {{- else if $parentTag -}}
        {{- $_ := set $imageDict "tag" $parentTag -}}
      {{- else if $fallbackTag -}}
        {{- $_ := set $imageDict "tag" $fallbackTag -}}
      {{- end -}}
    {{- end -}}

    {{- /* Copy other image properties (pullPolicy, etc) */ -}}
    {{- range $key, $val := $values.image -}}
      {{- if and (ne $key "repository") (ne $key "tag") (ne $key "ref") (ne $key "imageRef") -}}
        {{- $_ := set $imageDict $key $val -}}
      {{- end -}}
    {{- end -}}

    {{- $_ := set $result "image" $imageDict -}}
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

      {{- /* Priority 1: Complete reference */ -}}
      {{- if hasKey . "ref" -}}
        {{- $_ := set $imgDict "ref" .ref -}}
      {{- else if hasKey . "imageRef" -}}
        {{- $_ := set $imgDict "imageRef" .imageRef -}}
      {{- else -}}
        {{- /* Priority 2: Repository + Tag with fallback */ -}}
        {{- if hasKey . "repository" -}}
          {{- $_ := set $imgDict "repository" .repository -}}
        {{- end -}}

        {{- if hasKey . "tag" -}}
          {{- $_ := set $imgDict "tag" .tag -}}
        {{- else if $fallbackTag -}}
          {{- $_ := set $imgDict "tag" $fallbackTag -}}
        {{- end -}}
      {{- end -}}

      {{- /* Copy other properties */ -}}
      {{- range $key, $val := . -}}
        {{- if and (ne $key "name") (ne $key "repository") (ne $key "tag") (ne $key "ref") (ne $key "imageRef") -}}
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

      {{- /* Priority 1: Complete reference */ -}}
      {{- if hasKey $img "ref" -}}
        {{- $_ := set $imgDict "ref" $img.ref -}}
      {{- else if hasKey $img "imageRef" -}}
        {{- $_ := set $imgDict "imageRef" $img.imageRef -}}
      {{- else -}}
        {{- /* Priority 2: Repository + Tag with fallback */ -}}
        {{- if hasKey $img "repository" -}}
          {{- $_ := set $imgDict "repository" $img.repository -}}
        {{- end -}}

        {{- if hasKey $img "tag" -}}
          {{- $_ := set $imgDict "tag" $img.tag -}}
        {{- else if $fallbackTag -}}
          {{- $_ := set $imgDict "tag" $fallbackTag -}}
        {{- end -}}
      {{- end -}}

      {{- /* Copy other properties */ -}}
      {{- range $key, $val := $img -}}
        {{- if and (ne $key "repository") (ne $key "tag") (ne $key "ref") (ne $key "imageRef") -}}
          {{- $_ := set $imgDict $key $val -}}
        {{- end -}}
      {{- end -}}

      {{- $_ := set $imagesDict $name $imgDict -}}
    {{- end -}}
    {{- $_ := set $result "images" $imagesDict -}}
  {{- end -}}
{{- end -}}

{{- if $result -}}
{{- toYaml $result -}}
{{- end -}}
{{- end -}}

{{/*
Render OCI repository with smart fallback logic for tag.

Usage:
  {{ include "cc-gardener.extension.ociRepository" (dict "ociRepository" .helm.ociRepository "fallbackTag" .version) | indent 10 }}

Parameters:
  - ociRepository: The ociRepository dict
  - fallbackTag: The tag to use if not specified (typically .version)

Priority for references:
  1. ref (complete reference including tag)
  2. digest (SHA256 digest)
  3. repository + tag (or fallbackTag if tag not specified)
*/}}
{{- define "cc-gardener.extension.ociRepository" -}}
{{- $ociRepo := .ociRepository | default dict -}}
{{- $fallbackTag := .fallbackTag | default "" -}}
{{- /* Priority 1: Complete ref */ -}}
{{- if hasKey $ociRepo "ref" -}}
ref: {{ $ociRepo.ref }}
{{- else -}}
{{- /* Priority 2: Digest */ -}}
{{- if hasKey $ociRepo "digest" -}}
digest: {{ $ociRepo.digest }}
{{- end -}}
{{- /* Repository */ -}}
{{- if hasKey $ociRepo "repository" -}}
repository: {{ $ociRepo.repository }}
{{ end -}}
{{- /* Tag with fallback */ -}}
{{- if hasKey $ociRepo "tag" -}}
tag: {{ $ociRepo.tag }}
{{- else if $fallbackTag -}}
tag: {{ $fallbackTag }}
{{- end -}}
{{- end -}}
{{- /* pullSecretRef if present */ -}}
{{- if hasKey $ociRepo "pullSecretRef" -}}
pullSecretRef:
{{ toYaml $ociRepo.pullSecretRef | nindent 2 }}
{{- end -}}
{{- end -}}
