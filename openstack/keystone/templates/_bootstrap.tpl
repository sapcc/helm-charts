{{/* Resolve the shared LDAP profiles with the same precedence as domain-seeds. */}}
{{- define "keystone.bootstrap.ldapConfig" -}}
{{- $root := .root -}}
{{- $profileName := $root.Values.ldapProfile | default "ad" -}}
{{- $profile := get $root.Values.ldapProfiles $profileName | required (printf "Unknown LDAP profile %q in .Values.ldapProfiles" $profileName) -}}
{{- $domainOverrides := get ($profile.domains | default dict) .domain | default dict -}}
{{- $ldap := mergeOverwrite (deepCopy $root.Values.ldapDefaults) (deepCopy ($profile.ldap | default dict)) (deepCopy $domainOverrides) -}}
{{- $context := merge (dict "Domain" .domain) $root -}}
{{- range $key, $value := $ldap -}}
  {{- if eq $value nil -}}
    {{- $_ := unset $ldap $key -}}
  {{- else if kindIs "string" $value -}}
    {{- $_ := set $ldap $key (tpl $value $context) -}}
  {{- end -}}
{{- end -}}

{{/* Connection values, including credentials, remain literal strings. */}}
{{- $runtime := dict
  "url" ($root.Values.ldapUrl | toString)
  "user" ($root.Values.ldapUser | toString)
  "password" (required "A valid .Values.ldapPassword required!" $root.Values.ldapPassword | toString)
  "suffix" ($root.Values.ldapSuffix | toString)
  "use_pool" $root.Values.ldapUsePool
  "use_auth_pool" $root.Values.ldapUseAuthPool
  "debug_level" $root.Values.ldapDebugLevel
-}}
{{- $ldap = mergeOverwrite $ldap $runtime -}}
{{- range $key := $profile.requiredOptions -}}
  {{- $_ := required (printf "LDAP profile %q requires %s for domain %q; set ldapProfiles.%s.domains.%s.%s" $profileName $key $.domain $profileName $.domain $key) (get $ldap $key) -}}
{{- end -}}
identity:
  driver: {{ $root.Values.ldapDriver | default $profile.driver | required (printf "LDAP profile %q requires an identity driver" $profileName) | quote }}
ldap:
  {{- toYaml $ldap | nindent 2 }}
{{- end -}}

{{/* Give every principal and project reference an explicit domain name. */}}
{{- define "keystone.bootstrap.roleAssignment" -}}
{{- $assignment := deepCopy .assignment -}}
{{- $_ := set $assignment .kind .principal -}}
{{- if $assignment.project -}}
  {{- $_ := set $assignment "project" (dict "name" $assignment.project "domain" ($assignment.domain | default .domain)) -}}
  {{- $_ := unset $assignment "domain" -}}
{{- end -}}
{{- toYaml $assignment -}}
{{- end -}}
