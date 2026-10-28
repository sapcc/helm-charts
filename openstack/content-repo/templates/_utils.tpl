{{- define "image_version" -}}
  {{- if contains "DEFINED" .image_version -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{.image_version}}
  {{- end -}}
{{- end -}}

{{- define "secret_env_vars" -}}
{{- $targetPasswordKeys := dict "target_auth_password" true }}
{{- range $target := .targets }}
{{- $_ := set $targetPasswordKeys $target.password_key true }}
{{- end }}
{{- range $key, $val := .root.Values.passwords -}}
{{/* This loop includes the specific target-side password for this job, and also all passwords that are relevant on the source side (because we don't have a good way yet to filter for just the ones that this job needs). */}}
{{- if or (eq $key $.targetCfg.password_key) (not (hasKey $targetPasswordKeys $key)) }}
{{- if contains "DEFINED" $val }}
  {{ required "This release should be installed by the deployment pipeline!" "" }}
{{- end }}
{{- if eq $key $.targetCfg.password_key }}
- name: {{ include "content-repo.target_env" $.targetName }}
{{- else }}
- name: {{ $key | upper }}
{{- end }}
  valueFrom:
    secretKeyRef:
      name: swift-http-import
      key: {{ $key }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Returns the targets map. When .Values.targets is set it is returned as-is.
When it is absent the legacy .Values.target block is synthesized into a
single-entry map under the key "default" so the rest of the templates can
always range over a consistent structure.
*/}}
{{- define "content-repo.targets" -}}
{{- if .Values.targets -}}
{{ toYaml .Values.targets }}
{{- else -}}
default:
  auth_url:            {{ .Values.target.auth_url | default "" }}
  user_name:           {{ .Values.target.user_name }}
  user_domain_name:    {{ .Values.target.user_domain_name }}
  project_name:        {{ .Values.target.project_name }}
  project_domain_name: {{ .Values.target.project_domain_name }}
  service_type:        {{ .Values.target.service_type }}
  password_key:        target_auth_password
{{- end -}}
{{- end -}}

{{/*
Returns the resource/file suffix for a given target name.
The reserved name "default" returns an empty string (unsuffixed, back-compat).
All other names return "-<targetName>".
*/}}
{{- define "content-repo.target_suffix" -}}
{{- if eq . "default" -}}{{- else -}}-{{ . }}{{- end -}}
{{- end -}}

{{/*
Returns the name of the env var that holds the auth password for a given target.
The reserved name "default" returns "TARGET_AUTH_PASSWORD" (back-compat).
All other names return "<TARGET>_AUTH_PASSWORD" (upper-cased, hyphens->underscores).
*/}}
{{- define "content-repo.target_env" -}}
{{- if eq . "default" -}}
TARGET_AUTH_PASSWORD
{{- else -}}
{{ . | upper | replace "-" "_" }}_AUTH_PASSWORD
{{- end -}}
{{- end -}}

{{/*
For each target, check that destinations do not overlap.
*/}}
{{- define "content-repo.validate-destination-prefixes" -}}
{{- $root := .root -}}
{{- range $targetName, $targetCfg := .targets -}}

  {{/* Keep a separate list per target: jobs writing to different targets do not conflict. */}}
  {{- $destinations := list -}}
  {{- range $repo, $config := $root.Values.repos -}}

    {{/* Ignore disabled repos and repos explicitly assigned to a different target. */}}
    {{- if and (not $config.disabled) (or (not $config.only_target) (eq $targetName $config.only_target)) -}}

      {{- $deleteCleanup := eq ($config.cleanup_strategy | default "") "delete" -}}
      {{- $teamManaged := $config.team_managed_sources | default false -}}

      {{- range $jobIndex, $job := $config.jobs -}}
        {{- if and (hasKey $targetCfg "container") (not (or (kindIs "string" $targetCfg.container) (kindIs "invalid" $targetCfg.container))) -}}
          {{- fail (printf "target %q container must be a string, got %s" $targetName (kindOf $targetCfg.container)) -}}
        {{- end -}}
        {{- if and (hasKey $job.to "container") (not (or (kindIs "string" $job.to.container) (kindIs "invalid" $job.to.container))) -}}
          {{- fail (printf "repo %q job %d to.container must be a string, got %s" $repo $jobIndex (kindOf $job.to.container)) -}}
        {{- end -}}
        {{- if and (hasKey $job.to "object_prefix") (not (or (kindIs "string" $job.to.object_prefix) (kindIs "invalid" $job.to.object_prefix))) -}}
          {{- fail (printf "repo %q job %d to.object_prefix must be a string, got %s" $repo $jobIndex (kindOf $job.to.object_prefix)) -}}
        {{- end -}}

        {{/* Resolve the effective destination, preferring the target's container over the job's. */}}
        {{- $container := $targetCfg.container | default $job.to.container -}}
        {{- $prefix := $job.to.object_prefix | default "" -}}

        {{/* Normalize prefixes with trailing slashes */}}
        {{- if and $prefix (not (hasSuffix "/" $prefix)) -}}
          {{- $prefix = printf "%s/" $prefix -}}
        {{- end -}}

        {{- $jobDestinations := list (dict "kind" "main" "container" $container "prefix" $prefix "deleteCleanup" $deleteCleanup "teamManaged" $teamManaged) -}}

        {{/* Compare against destinations from earlier jobs, then record all this job's destinations. */}}
        {{- range $current := $jobDestinations -}}
          {{- range $existing := $destinations -}}
            {{/* Check both directions: either prefix may be the broader destination. */}}
            {{- if and (eq $current.container $existing.container) (or $current.teamManaged $existing.teamManaged) (or $current.deleteCleanup $existing.deleteCleanup) (or (hasPrefix $existing.prefix $current.prefix) (hasPrefix $current.prefix $existing.prefix)) -}}
              {{- fail (printf "repo %q job %d %s destination (container %q, prefix %q) overlaps repo %q job %d %s destination (container %q, prefix %q) for target %q; delete cleanup can remove the other job's objects" $repo $jobIndex $current.kind $current.container $current.prefix $existing.repo $existing.jobIndex $existing.kind $existing.container $existing.prefix $targetName) -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
        {{- range $current := $jobDestinations -}}
          {{- $destinations = append $destinations (merge (dict "repo" $repo "jobIndex" $jobIndex) $current) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}
