{{/*
  Generate Kubernetes service template
  service without per pod information:  include "networkService" (dict "global" $ "type" "backend" "service" $service "component" $component "replica" "notused")
  service with per pod information:     include "networkService" (dict "global" $ "type" "backend" "service" $service "component" $component "replica" ($replicaNumber|toString))
*/}}
{{- define "networkService" }}
{{ $nodeNamePrefix := "" }}
{{ if or (eq .component "application") (eq .component "application-direct") }}
  {{ $nodeNamePrefix = (include "nodeNamePrefix" (dict "global" .global "component" "application")) }}
{{ else }}
  {{ $nodeNamePrefix = (include "nodeNamePrefix" (dict "global" .global "component" .component)) }}
{{ end }}
---
apiVersion: v1
kind: Service
metadata:
  namespace: {{ .global.Release.Namespace }}
  {{- if eq .replica "notused" }}
    {{- if and (eq .type "frontend") (.global.Values.proxy.enabled) (or (eq .component "proxysql") (eq .component "haproxy"))}}
  name: {{ (printf "%s-%s" (include "nodeNamePrefix" (dict "global" .global "component" "application")) "frontend") }}
    {{- else if and (eq .type "frontend") (eq .component "application-direct")}}
  name: {{ (printf "%s-%s-direct" $nodeNamePrefix "frontend") }}
    {{- else }}
  name: {{ (printf "%s-%s" $nodeNamePrefix .type) }}
    {{- end }}
  {{- else }}
  name: {{ (printf "%s-%s" $nodeNamePrefix .replica) }}
  {{- end }}
  annotations:
  {{- if (hasKey .global.Values "OpenstackFloatingNetworkId") }}
    loadbalancer.openstack.org/keep-floatingip: "false"
    loadbalancer.openstack.org/floating-network-id: {{ .global.Values.OpenstackFloatingNetworkId }}
  {{- end }}
  {{- if (hasKey .global.Values "OpenstackSubnetId") }}
    loadbalancer.openstack.org/subnet-id: {{ .global.Values.OpenstackSubnetId }}
  {{- end }}
  {{- if (hasKey .global.Values "OpenstackFloatingSubnetId") }}
    loadbalancer.openstack.org/floating-subnet-id: {{ .global.Values.OpenstackFloatingSubnetId }}
  {{- end }}
  labels:
    app: {{ .global.Release.Name }}
spec:
  type: {{ required "the network service type has to be defined" .service.type }}
  {{- if .service.headless }}
  clusterIP: None
  publishNotReadyAddresses: true {{/* create A records for not ready pods and announce the IPs on the headless service before they are ready https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-hostname-and-subdomain-fields */}}
  {{- end }}
  selector:
  {{- if ne .replica "notused" }}
    statefulset.kubernetes.io/pod-name: {{ (printf "%s-%s" $nodeNamePrefix .replica) }}
  {{- else if and (hasKey .global.Values.mariadb "autostart") (not .global.Values.mariadb.autostart) }}
    component: "disabledBecauseOf-mariadb.autostart-disabled"
  {{- else if and (.global.Values.command) (hasKey .global.Values.command "application") }}
    component: "disabledBecauseOf-command.application-defined"
  {{- else if and (hasKey .global.Values.mariadb "wipeDataAndLog") (.global.Values.mariadb.wipeDataAndLog) }}
    component: "disabledBecauseOf-mariadb.wipeDataAndLog-enabled"
  {{- else if and (hasKey .global.Values.mariadb.galera.restore "kopia") (.global.Values.mariadb.galera.restore.kopia.enabled) }}
    component: "disabledBecauseOf-mariadb.galera.restore-enabled"
  {{- else if eq .component "application-direct" }}
    component: "application"
  {{- else }}
    component: {{ .component | quote }}
  {{- end }}
  ports:
  {{- range $portKey, $portValue := .service.ports }}
    - name: {{ $portKey }}
      port: {{ $portValue.port }}
      targetPort: {{ $portValue.targetPort }}
      protocol: {{ $portValue.protocol | default "TCP" }}
  {{- end }}
  sessionAffinity: {{ .service.sessionAffinity.type | default "None" | quote }}
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: {{ .service.sessionAffinity.ClientIpTimeoutSeconds | default "10800" | int }}
{{- end }}

{{/*
  render an prefix based on the mariadb.galera.clustername value
  include "commonPrefix" .
*/}}
{{- define "commonPrefix" }}
  {{- if and (hasKey .Values.mariadb.galera "clustername") (.Values.mariadb.galera.clustername) }}
    {{- printf "%s-" .Values.mariadb.galera.clustername }}
  {{- end }}
{{- end }}


{{/*
  Fetch current node name prefix for a component (currently application and proxy are supported)
  application node name prefix:   include "nodeNamePrefix" (dict "global" $ "component" "application")
  proxysql node name prefix:      include "nodeNamePrefix" (dict "global" $ "component" "proxysql")
*/}}
{{- define "nodeNamePrefix" }}
  {{- if eq .component "application" }}
    {{- if and (.global.Values.namePrefix) (hasKey .global.Values.namePrefix .component) }}
      {{- printf "%s%s" (include "commonPrefix" .global) (.global.Values.namePrefix.application | default "mariadb-g") }}
    {{- else }}
      {{- printf "%s%s" (include "commonPrefix" .global) "mariadb-g" }}
    {{- end }}
  {{- else if eq .component "proxysql" }}
    {{- if and (.global.Values.namePrefix.proxy) (hasKey .global.Values.namePrefix.proxy .component) }}
      {{- printf "%s%s" (include "commonPrefix" .global) (.global.Values.namePrefix.proxy.proxysql | default "proxysql") }}
    {{- else }}
      {{- printf "%s%s" (include "commonPrefix" .global) "proxysql" }}
    {{- end }}
  {{- else if eq .component "kopiaserver" }}
    {{- if and (.global.Values.namePrefix) (hasKey .global.Values.namePrefix .component) }}
      {{- printf "%s%s" (include "commonPrefix" .global) (.global.Values.namePrefix.kopiaserver | default "backup-kopiaserver") }}
    {{- else }}
      {{- printf "%s%s" (include "commonPrefix" .global) "backup-kopiaserver" }}
    {{- end }}
  {{- else if eq .component "haproxy" }}
    {{- if and (.global.Values.namePrefix.proxy) (hasKey .global.Values.namePrefix.proxy .component) }}
      {{- printf "%s%s" (include "commonPrefix" .global) (.global.Values.namePrefix.proxy.haproxy | default "haproxy") }}
    {{- else }}
      {{- printf "%s%s" (include "commonPrefix" .global) "haproxy" }}
    {{- end }}
  {{- else }}
    {{- fail "No supported component provided for the nodeNamePrefix function" }}
  {{- end }}
{{- end }}


{{/*
  Generate 'wsrep_cluster_address' value
  include "wsrepClusterAddress" (dict "global" $)
*/}}
{{- define "wsrepClusterAddress" }}
  {{- $galeraPort := "" }}
  {{- $nodeNames := list -}}
  {{- $nodeNamePrefix := (include "nodeNamePrefix" (dict "global" .global "component" "application")) -}}
  {{- range $int, $err := until ($.global.Values.replicas.application|int) }}
    {{- $nodeNames = (printf "%s-%d.%s.svc.cluster.local:%d" $nodeNamePrefix $int $.global.Release.Namespace ((required ".services.application.backend.ports.galera.targetPort missing" $.global.Values.services.application.backend.ports.galera.port) | int)) | append $nodeNames -}}
  {{- end }}
  {{- (printf "gcomm://%s,%s-backend.%s.svc.cluster.local:%d" (join "," $nodeNames) $nodeNamePrefix $.global.Release.Namespace ((required ".services.application.backend.ports.galera.targetPort missing" $.global.Values.services.application.backend.ports.galera.port) | int)) }}
{{- end }}

{{/*
  fetch a certain environment variable value
  include "getEnvVar" (dict "global" $ "name" "MARIADB_CLUSTER_NAME")
*/}}
{{- define "getEnvVar" }}
  {{- range $envKey, $envValue := $.global.Values.env }}
    {{- if eq $envKey $.name }}
      {{- if $envValue.secretName }}
        {{- $envValue.secretKey }}
      {{- else }}
        {{- $envValue.value }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
  fetch a certain network port value
  include "getNetworkPort" (dict "global" $ "type" "backend" "name" "ist")
*/}}
{{- define "getNetworkPort" }}
  {{- range $servicesKey, $servicesValue := $.global.Values.services.application }}
    {{- if eq $servicesValue.name $.type }}
      {{- range $portsKey, $portsValue := $servicesValue.ports }}
        {{- if eq $portsValue.name $.name }}
          {{- ($portsValue.port | int) }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
  Generate server-id list value
  include "serverIdList" (dict "global" $)
*/}}
{{- define "serverIdList" }}
  {{- $serverIds := list -}}
  {{- range $int, $err := until ($.global.Values.replicas.application|int) }}
    {{- $serverIds = ((printf "%d%d" ($.global.Values.mariadb.galera.gtidDomainId | default 1 | int) $int) | int) | append $serverIds -}}
  {{- end }}
  {{- (join "," $serverIds) }}
{{- end }}

{{/*
  Generate domain id list value
  include "domainIdList" (dict "global" $)
*/}}
{{- define "domainIdList" }}
  {{- $domainIds := list -}}
  {{- range $int, $err := until 2 }}
    {{- $domainIds = ((printf "%d%d%d%d%d" ((add1 $int) | int) 0 8 1 5) | int) | append $domainIds -}}
  {{- end }}
  {{- (join "," $domainIds) }}
{{- end }}

{{/*
  Generate Kubernetes secrets based on the provided credentials
  include "generateSecret" (dict "global" $ "name" $credentialKey "credential" $credentialValue "suffix" "mariadb" "kind" "Secret")
  include "generateSecret" (dict "global" $ "name" $credentialKey "credential" $credentialValue "kind" "Dockerconfigjson")
*/}}
{{- define "generateSecret" }}
  {{- if eq $.kind "Secret" }}
    {{- include "generateSecretKindSecret" (dict "global" .global "name" $.name "credential" $.credential "suffix" $.suffix) }}
  {{- end }}
  {{- if eq $.kind "Dockerconfigjson" }}
    {{- include "generateSecretKindDockerconfigjson" (dict "global" .global "name" $.name "credential" $.credential "suffix" $.suffix) }}
  {{- end }}
{{- end }}

{{/*
  Generate Kubernetes secret kind structure
  include "generateSecretKindSecret" (dict "global" .global "name" $.name "credential" $.credential "suffix" $.suffix)
*/}}
{{- define "generateSecretKindSecret" }}
- apiVersion: v1
  kind: Secret
  type: Opaque
  metadata:
    namespace: {{ $.global.Release.Namespace }}
    name: {{ include "commonPrefix" .global }}{{ $.global.Release.Name }}-{{ $.suffix }}-{{ $.name }}
  data:
  {{- if $.credential.username }}
    username: {{ $.credential.username | b64enc }}
  {{- end }}
    password: {{ (required (printf "%s.users.%s.password is required to configure the Kubernetes secret for the '%s' user" $.suffix $.name $.name) $.credential.password) | b64enc }}
{{- end }}

{{/*
  Generate Kubernetes secret kind structure
  include "generateSecretKindDockerconfigjson" (dict "global" .global "name" $.name "credential" $.credential "suffix" $.suffix)
*/}}
{{- define "generateSecretKindDockerconfigjson" }}
- apiVersion: v1
  kind: Secret
  type: kubernetes.io/dockerconfigjson
  metadata:
    namespace: {{ $.global.Release.Namespace }}
    name: {{ include "commonPrefix" .global }}{{ $.global.Release.Name }}-pullsecret-{{ $.name }}
  data:
    .dockerconfigjson: {{ printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" (required (printf "image.pullSecrets.%s.registry is required to configure the Kubernetes pull secret '%s'" $.name $.name) $.credential.registry) (printf "%s" (required (printf "image.pullSecrets.%s.credential is required to configure the Kubernetes pull secret '%s'" $.name $.name) $.credential.credential) | b64enc) | b64enc }}
{{- end }}
