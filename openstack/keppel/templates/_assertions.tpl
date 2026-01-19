{{/* This file contains assertions that we test only once, to reduce the amount
     of `| required "missing value"` or `| default (dict)` elsewhere. */}}

{{- $p := index .Values.keppel.peer_groups .Values.keppel.peer_group | required "missing peer group config" -}}
{{- if ne (kindOf $p.leader) "string" -}}
  {{- fail (printf "expected string for \"leader\" attribute of peer group, but got %#v") $p.leader -}}
{{- end -}}
{{- if ne (kindOf $p.members) "slice" -}}
  {{- fail (printf "expected string for \"members\" attribute of peer group, but got %#v") $p.members -}}
{{- end -}}
{{- if ne (kindOf $p.anycast_domain_name) "string" -}}
  {{- fail (printf "expected string for \"anycast_domain_name\" attribute of peer group, but got %#v") $p.anycast_domain_name -}}
{{- end -}}
{{- if ne (kindOf $p.exclude_from_anycast) "slice" -}}
  {{- fail (printf "expected string for \"exclude_from_anycast\" attribute of peer group, but got %#v") $p.exclude_from_anycast -}}
{{- end -}}
{{- if ne (kindOf $p.exclude_from_pull_delegation) "slice" -}}
  {{- fail (printf "expected string for \"exclude_from_anycast\" attribute of peer group, but got %#v") $p.exclude_from_pull_delegation -}}
{{- end -}}
