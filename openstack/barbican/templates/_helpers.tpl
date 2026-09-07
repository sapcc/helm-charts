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

{{- define "barbican.external_ip" -}}
{{- $svc := .Values.services | default dict -}}
{{- .Values.global.barbican_external_ip | default $svc.externalip -}}
{{- end -}}

{{- define "barbican.db_service" }}
  {{- include "utils.db_host" . }}
{{- end }}

{{- define "barbican.service_dependencies" }}
  {{- template "barbican.db_service" . }}
{{- end }}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $all := list
          (include (print .Template.BasePath "/etc-configmap.yaml") .)
          (include (print .Template.BasePath "/secrets.yaml") .)
          (include "utils.proxysql.job_pod_settings" .)
          (include "utils.proxysql.volume_mount" .)
          (include "utils.proxysql.container" .)
          (include "utils.proxysql.volumes" .)
          (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container")
      | join "\n" }}
    {{- $hash := $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.imageVersionBarbicanApi | required "Please set barbican.imageVersionBarbicanApi" }}
  {{- end }}
{{- end }}

{{- define "barbican.tls.validate" -}}
{{- if .Values.tls.enabled }}
  {{- if .Values.tls.allowDisable }}
    {{- fail "tls.allowDisable must not be set while tls.enabled is true. It only authorizes the single rollout that turns TLS off; leaving it set silently disarms the teardown guard on the next disable. Remove tls.allowDisable from the values." }}
  {{- end }}
  {{- if not .Values.tls.keyGeneration }}
    {{- fail "tls.keyGeneration is required when tls.enabled (options: go-crypto, hsm-entropy, hsm-full, tpm-entropy)" }}
  {{- end }}
  {{- if not .Values.tls.keyWrapping }}
    {{- fail "tls.keyWrapping is required when tls.enabled (options: none, vault-transit, hsm, tpm)" }}
  {{- end }}
  {{- if not .Values.tls.keyStorage }}
    {{- fail "tls.keyStorage is required when tls.enabled (options: internal-k8s-secret, k8s-secret, vault-secret)" }}
  {{- end }}
  {{- if and (eq .Values.tls.keyWrapping "none") (eq .Values.tls.keyStorage "k8s-secret") (not .Values.tls.allowInsecureStorage) }}
    {{- fail "tls: unwrapped keys cannot be stored as plain-text K8s Secrets. Set tls.keyWrapping or tls.keyStorage, or set tls.allowInsecureStorage: true to acknowledge." }}
  {{- end }}
  {{- $svc := .Values.services | default dict }}
  {{- if not (.Values.global.barbican_external_ip | default $svc.externalip) }}
    {{- fail "tls.enabled requires an external IP (global.barbican_external_ip or services.externalip): enabling TLS removes the ingress and the public TLS Service only renders once the external IP is set." }}
  {{- end }}
{{- else }}
  {{- /* Teardown guard: TLS is off in the values, but if the public TLS Service
         still exists this upgrade would tear down pod-level TLS. That removes the
         LoadBalancer and the disco Record pinning the endpoint to the external IP;
         since the endpoint is not disco-managed, it stops resolving until the
         region's baseline DNS is restored. Fail the render (before Helm touches
         anything) unless the teardown is acknowledged. */}}
  {{- $tlsSvc := lookup "v1" "Service" .Release.Namespace "barbican-public-tls" }}
  {{- if and $tlsSvc (not .Values.tls.allowDisable) }}
    {{- $host := include "barbican_api_endpoint_host_public" . }}
    {{- fail (printf "Refusing to disable pod-level TLS: the barbican-public-tls LoadBalancer still exists, so TLS termination is currently active. Disabling removes it and the disco Record pinning %s to the external IP; because %s is not disco-managed, the public endpoint stops resolving until the region's baseline DNS is restored. To tear down intentionally, repoint %s DNS back to the ingress first, then set tls.allowDisable=true for this rollout." $host $host $host) }}
  {{- end }}
{{- end }}
{{- end }}
