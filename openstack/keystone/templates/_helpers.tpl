{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{- define "keystone.memcached_host" -}}
{{- if .Values.global.is_global_region -}}
{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}
{{- else -}}
{{.Release.Name}}-memcached.{{ include "svc_fqdn" . }}
{{- end -}}
{{- end -}}

{{- define "keystone.service_dependencies" }}
  {{- template "keystone.db_service" . }},{{ template "keystone.memcached_service" . }}
{{- end }}

{{- define "keystone.db_service" }}
  {{- if or .Values.percona_cluster.enabled (eq .Values.dbType "pxc-global") }}
    {{- .Release.Name }}-percona-pxc
  {{- else }}
    {{- include "utils.db_host" . }}
  {{- end }}
{{- end }}

{{- define "keystone.memcached_service" }}
{{- .Release.Name }}-memcached
{{- end }}

{{- define "2faproxy.selectorLabels" -}}
app.kubernetes.io/name: 2faproxy
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "2faproxy.labels" -}}
helm.sh/chart: {{ include "name" . }}
{{ include "2faproxy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- /* Rerun each Job on every Helm release revision. */}}
    {{- $suffix := printf "-%s-r%d" $name .Release.Revision }}
    {{- /* Keep the Job kind and revision intact within the 63-character limit. */}}
    {{- $prefixLength := sub 63 (len $suffix) | int }}
    {{- $prefix := .Release.Name | trunc $prefixLength | trimSuffix "-" }}
    {{- printf "%s%s" $prefix $suffix }}
  {{- end }}
{{- end }}

{{- define "keystone.job_dependencies" }}
  {{- $jobs := list }}
  {{- if include "keystone.migration_enabled" . }}
    {{- $jobs = append $jobs (tuple . "job-migration" | include "job_name") }}
  {{- end }}
  {{- $jobs = append $jobs (tuple . "job-bootstrap" | include "job_name") }}
  {{- join "," $jobs }}
{{- end }}

{{/* Stable, revision-scoped inputs for Jobs and the API startup check. */}}
{{- define "keystone.upgrade_config" -}}
{{- tuple . "upgrade-config" | include "job_name" -}}
{{- end -}}

{{- define "keystone.upgrade_labels" }}
cloud.sap/keystone-release: {{ .Release.Name | quote }}
cloud.sap/keystone-revision: {{ .Release.Revision | quote }}
{{- end }}

{{- define "keystone.migration_enabled" -}}
{{- if or .Values.run_db_migration .Release.IsInstall -}}true{{- end -}}
{{- end -}}

{{/* Bypass ProxySQL for startup checks, including legacy non-native sidecars.
     The FQDN avoids the ProxySQL pod's short-name hostAliases. */}}
{{- define "keystone.direct_db_url" -}}
{{- if or .Values.percona_cluster.enabled (eq .Values.dbType "pxc-global") -}}
  {{- include "db_url_pxc" . -}}
{{- else -}}
  {{- $values := deepCopy .Values -}}
  {{- $_ := set $values.proxysql "mode" "" -}}
  {{- $host := include "keystone.db_service" . -}}
  {{- include "utils.db_url" (dict "Values" $values) | replace (printf "@%s/" $host) (printf "@%s.%s/" $host (include "svc_fqdn" .)) -}}
{{- end -}}
{{- end -}}

{{- define "keystone.rollout_env" }}
- name: KEYSTONE_RELEASE
  value: {{ .Release.Name | quote }}
- name: KEYSTONE_NAMESPACE
  value: {{ .Release.Namespace | quote }}
- name: KEYSTONE_REVISION
  value: {{ .Release.Revision | quote }}
- name: KEYSTONE_API_IMAGE
  value: {{ printf "%s/%s:%v" .Values.global.registryAlternateRegion .Values.api.image .Values.api.imageTag | quote }}
{{- end }}

{{/* Call after kubernetes-entrypoint; requires the keystone-bin volume. */}}
{{- define "keystone.schema_check_init_container" }}
- name: keystone-schema-check
  image: {{ required ".Values.global.registryAlternateRegion is missing" .Values.global.registryAlternateRegion }}/{{ .Values.api.image }}:{{ required ".Values.api.imageTag is missing" .Values.api.imageTag }}
  imagePullPolicy: {{ .Values.api.imagePullPolicy | default "IfNotPresent" | quote }}
  command: [bash, /scripts/schema-check]
  volumeMounts:
    {{- include "keystone.startup_check_volume_mounts" . | nindent 4 }}
    - name: keystone-bin
      mountPath: /scripts
      readOnly: true
{{- end }}

{{- define "keystone.upgrade_check_init_container" }}
- name: keystone-upgrade-check
  image: {{ required ".Values.global.registryAlternateRegion is missing" .Values.global.registryAlternateRegion }}/{{ .Values.api.image }}:{{ required ".Values.api.imageTag is missing" .Values.api.imageTag }}
  imagePullPolicy: {{ .Values.api.imagePullPolicy | default "IfNotPresent" | quote }}
  command: [bash, /upgrade/upgrade-check]
  volumeMounts:
    {{- include "keystone.startup_check_volume_mounts" . | nindent 4 }}
    - name: upgrade
      mountPath: /upgrade
      readOnly: true
{{- end }}

{{- define "keystone.startup_check_volume_mounts" }}
- name: keystone-etc
  mountPath: /etc/keystone/keystone.conf
  subPath: keystone.conf
  readOnly: true
- name: keystone-etc
  mountPath: /etc/keystone/logging.conf
  subPath: logging.conf
  readOnly: true
- name: keystone-etc
  mountPath: /etc/keystone/policy.yaml
  subPath: policy.yaml
  readOnly: true
- name: keystone-etc-confd
  mountPath: /etc/keystone/keystone.conf.d
  readOnly: true
- name: fernet
  mountPath: /fernet-keys
  readOnly: true
- name: credential-keys
  mountPath: /credential-keys
  readOnly: true
{{- include "utils.trust_bundle.volume_mount" . }}
{{- end }}

{{/* Database-checking init containers need the mesh proxy to be running first. */}}
{{- define "keystone.startup_linkerd_annotation" -}}
{{- $values := deepCopy .Values -}}
{{- $_ := set $values.global "linkerd_use_native_sidecar" true -}}
{{- include "utils.linkerd.pod_and_service_annotation" (dict "Values" $values) -}}
{{- end -}}

{{/*
kubernetes-entrypoint init container using the sapcc fork from ghcrIoMirrorAlternateRegion.
Usage: tuple . (dict "SERVICE" "svc1,svc2" "JOBS" "job1") | include "keystone.kubernetes_entrypoint_init_container" | indent N
Empty values are skipped so callers may pass "" for optional dependencies.
*/}}
{{- define "keystone.kubernetes_entrypoint_init_container" }}
  {{- $envAll := index . 0 }}
  {{- $params := index . 1 }}
- name: kubernetes-entrypoint
  image: {{ $envAll.Values.global.ghcrIoMirrorAlternateRegion | required ".Values.global.ghcrIoMirrorAlternateRegion unset " }}/sapcc/kubernetes-entrypoint:{{ $envAll.Values.imageVersionKubernetesEntrypoint | required ".Values.imageVersionKubernetesEntrypoint is unset" }}
  command:
  - kubernetes-entrypoint
  env:
  - name: COMMAND
    value: "true"
  - name: POD_NAME
    valueFrom: {fieldRef: {fieldPath: metadata.name}}
  - name: NAMESPACE
    valueFrom: {fieldRef: {fieldPath: metadata.namespace}}
  {{- range $k, $v := $params }}
  {{- if $v }}
  - name: DEPENDENCY_{{ $k | upper }}
    value: {{ $v }}
  {{- end }}
  {{- end }}
{{- end }}

{{- define "prodel_url" }}
    {{- if not (empty .Values.prodel.url) -}}
        {{- .Values.prodel.url -}}
    {{- else -}}
        {{- $ns := "prodel" -}}

        {{- if .Values.global.is_global_region -}}
        {{- $ns = .Values.prodel.prodelNamespace | default "prodel" -}}
        {{- end -}}

        {{- printf "http://prodel.%s.svc/check-delete_project/%%(project_id)s" $ns -}}
    {{- end }}
{{- end }}

{{- define "keystone.tls.serving" -}}
{{- if or (eq .Values.tls.state "transition") (eq .Values.tls.state "enabled") -}}true{{- end -}}
{{- end -}}

{{- define "keystone.tls.ingressActive" -}}
{{- if or (eq .Values.tls.state "disabled") (eq .Values.tls.state "transition") -}}true{{- end -}}
{{- end -}}

{{- define "keystone.tls.validate" -}}
{{- if not (has .Values.tls.state (list "disabled" "transition" "enabled")) }}
  {{- fail "tls.state must be one of: disabled, transition, enabled" }}
{{- end }}
{{- if include "keystone.tls.serving" . }}
  {{- if not .Values.tls.keyGeneration }}
    {{- fail "tls.keyGeneration is required when TLS is serving (options: go-crypto, hsm-entropy, hsm-full, tpm-entropy)" }}
  {{- end }}
  {{- if not .Values.tls.keyWrapping }}
    {{- fail "tls.keyWrapping is required when TLS is serving (options: none, vault-transit, hsm, tpm)" }}
  {{- end }}
  {{- if not .Values.tls.keyStorage }}
    {{- fail "tls.keyStorage is required when TLS is serving (options: internal-k8s-secret, k8s-secret, vault-secret)" }}
  {{- end }}
  {{- if and (eq .Values.tls.keyWrapping "none") (eq .Values.tls.keyStorage "k8s-secret") (not .Values.tls.allowInsecureStorage) }}
    {{- fail "tls: unwrapped keys cannot be stored as plain-text K8s Secrets. Set tls.keyWrapping or tls.keyStorage, or set tls.allowInsecureStorage: true to acknowledge." }}
  {{- end }}
  {{- if not .Values.global.keystone_external_ip }}
    {{- fail "TLS serving requires global.keystone_external_ip: the public TLS Service only renders once the external IP is set." }}
  {{- end }}
  {{- /* Guard the CSP script-src hash against drift: the TLS vhost pins a
         sha256 of the WebSSO callback's inline auto-submit script, and Helm
         cannot recompute a base64 digest, so fail loudly if the script changes
         and both pins must be refreshed together. */}}
  {{- $ssoTpl := include (print $.Template.BasePath "/etc/_sso_callback_template.html.tpl") . }}
  {{- $ssoParts := splitList "<script type=\"text/javascript\">" $ssoTpl }}
  {{- if lt (len $ssoParts) 2 }}
    {{- fail "SSO callback template: could not locate the <script> block; update the CSP script-src hash guard in keystone.tls.validate." }}
  {{- end }}
  {{- $ssoScript := index (splitList "</script>" (index $ssoParts 1)) 0 }}
  {{- if ne (sha256sum $ssoScript) "a016a19411507a6fa732cd49c20701074dc7cbc9d18797bca8419339cc6602e3" }}
    {{- fail "SSO callback inline script changed; recompute the CSP script-src hash (sha256/base64 of the <script> body) in etc/_wsgi-keystone.conf.tpl and update the pinned hash here." }}
  {{- end }}
{{- end }}
{{- $dep := lookup "apps/v1" "Deployment" .Release.Namespace (printf "%s-api" .Release.Name) }}
{{- if $dep }}
  {{- $current := index (default dict $dep.metadata.annotations) "cloud.sap/tls-state" }}
  {{- if has $current (list "disabled" "transition" "enabled") }}
    {{- if or (and (eq $current "disabled") (eq .Values.tls.state "enabled")) (and (eq $current "enabled") (eq .Values.tls.state "disabled")) }}
      {{- fail (printf "tls.state cannot change directly from %s to %s; move through transition first." $current .Values.tls.state) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
