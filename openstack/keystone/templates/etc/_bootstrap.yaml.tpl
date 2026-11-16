{{- $seed := include "keystone.seed" . | fromYaml -}}
{{- $bootstrap := omit $seed "domains" -}}
{{- $domains := list -}}
{{- $projects := list -}}
{{- $users := list -}}
{{- $groups := list -}}
{{- $memberships := list -}}
{{- $assignments := list -}}
{{- $secretRefs := dict -}}

{{/* Flatten the baseline so the command consumes one domain-qualified format. */}}
{{- range $seed.domains -}}
  {{- $domain := .name -}}
  {{- $domainData := . -}}
  {{- $domains = append $domains (omit . "projects" "users" "groups") -}}
  {{- range .projects -}}
    {{- $projects = append $projects (merge (dict "domain" $domain) .) -}}
  {{- end -}}
  {{- range $kind := list "users" "groups" -}}
    {{- range get $domainData $kind -}}
      {{- $principal := dict "name" .name "domain" $domain -}}
      {{- $entity := merge (dict "domain" $domain) (omit . "role_assignments" "users") -}}
      {{- if eq $kind "users" -}}
        {{- $users = append $users $entity -}}
      {{- else -}}
        {{- $groups = append $groups $entity -}}
        {{- range .users -}}
          {{- $memberships = append $memberships (dict "group" $principal "user" (dict "name" . "domain" $domain)) -}}
        {{- end -}}
      {{- end -}}
      {{- range .role_assignments -}}
        {{- $assignment := include "keystone.bootstrap.roleAssignment" (dict "assignment" . "domain" $domain "kind" (ternary "user" "group" (eq $kind "users")) "principal" $principal) | fromYaml -}}
        {{- $assignments = append $assignments $assignment -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- range .Values.keystoneBootstrap.domains -}}
  {{- $domain := deepCopy . -}}
  {{- $_ := set $domain "config" (include "keystone.bootstrap.ldapConfig" (dict "root" $ "domain" .name) | fromYaml) -}}
  {{/* Keep deferred expressions out of toYaml so it cannot quote or escape them. */}}
  {{- range $key, $value := $domain.config.ldap -}}
    {{- if and (kindIs "string" $value) (hasPrefix "vault+kvv2:///" $value) -}}
      {{- $placeholder := printf "KEYSTONE_BOOTSTRAP_SECRET_%s" (sha256sum $value) -}}
      {{- $_ := set $secretRefs $placeholder $value -}}
      {{- $_ := set $domain.config.ldap $key $placeholder -}}
    {{- end -}}
  {{- end -}}
  {{- $domains = append $domains $domain -}}
{{- end -}}
{{- $projects = concat $projects (.Values.keystoneBootstrap.projects | default list) -}}
{{- range .Values.keystoneBootstrap.role_assignments -}}
  {{- range . -}}
    {{- $principal := dict "name" .group "domain" .domain -}}
    {{- $assignment := include "keystone.bootstrap.roleAssignment" (dict "assignment" . "domain" .domain "kind" "group" "principal" $principal) | fromYaml -}}
    {{- $assignments = append $assignments $assignment -}}
  {{- end -}}
{{- end -}}

{{- $_ := set $bootstrap "domains" $domains -}}
{{- $_ := set $bootstrap "projects" $projects -}}
{{- $_ := set $bootstrap "users" $users -}}
{{- $_ := set $bootstrap "groups" $groups -}}
{{- $_ := set $bootstrap "group_memberships" $memberships -}}
{{- $_ := set $bootstrap "role_assignments" $assignments -}}

{{/* Escape literal delimiters; secrets-injector quotes resolved values as YAML-safe JSON strings. */}}
{{- $yaml := toYaml $bootstrap | replace "{{" "{{ \"{{\" }}" -}}
{{- range $placeholder, $reference := $secretRefs -}}
  {{- $yaml = replace $placeholder (printf "{{ resolve %q | toJson }}" $reference) $yaml -}}
{{- end -}}
{{- $yaml -}}
