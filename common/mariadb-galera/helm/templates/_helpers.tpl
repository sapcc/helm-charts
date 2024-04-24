{{/*
  Generate Kubernetes service template
  service without per pod information:  include "networkService" (dict "global" $ "type" "backend" "service" $service "component" $component "replica" "notused")
  service with per pod information:     include "networkService" (dict "global" $ "type" "backend" "service" $service "component" $component "replica" ($replicaNumber|toString))
*/}}
{{- define "networkService" }}
{{ $nodeNamePrefix := "" }}
{{ if or (eq .component "database") (eq .component "database-direct") }}
  {{ $nodeNamePrefix = (include "nodeNamePrefix" (dict "global" .global "component" "database")) }}
{{ else }}
  {{ $nodeNamePrefix = (include "nodeNamePrefix" (dict "global" .global "component" .component)) }}
{{ end }}
---
apiVersion: v1
kind: Service
metadata:
  namespace: {{ .global.Release.Namespace }}
  {{- if eq .replica "notused" }}
    {{- if and (eq .type "frontend") (or (eq .component "database") (eq .component "proxysql") (eq .component "haproxy"))}}
      {{- if .global.Values.mariadb.migration.enabled }}
  name: {{ (printf "%s-%s" (include "commonPrefix" .global) "mariadb-replica") }}
      {{- else }}
  name: {{ (printf "%s-%s" (include "commonPrefix" .global) "mariadb") }}
      {{- end }}
    {{- else if and (eq .type "frontend") (eq .component "database-direct")}}
  name: {{ (printf "%s-%s-direct" (include "commonPrefix" .global) "mariadb") }}
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
  {{- if and (.global.Values.mariadb.galera.multiRegion.enabled) (eq .type "backend") (eq .component "database") (eq .service.type "LoadBalancer") (eq .replica "notused") }}
    loadbalancer.openstack.org/enable-health-monitor: "false"
  {{- end }}

  labels:
    app: {{ .global.Release.Name }}
spec:
  {{- if and (.service.headless) (ne .service.type "LoadBalancer") (eq .replica "notused") }}
  type: {{ required "the network service type has to be defined" .service.type }}
  clusterIP: None
  {{- else if and (.service.headless) ( ne .replica "notused") }}
  type: ClusterIP
  clusterIP: None
  {{- else }}
  type: {{ required "the network service type has to be defined" .service.type }}
  {{- end }}
  {{- if and (.service.headless) (eq .type "backend") (eq .component "database") }}
  publishNotReadyAddresses: true {{/* create A records for not ready pods and announce the IPs on the headless service before they are ready https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-hostname-and-subdomain-fields */}}
  {{- end }}
  selector:
  {{- if ne .replica "notused" }}
    statefulset.kubernetes.io/pod-name: {{ (printf "%s-%s" $nodeNamePrefix .replica) }}
  {{- else if and (hasKey .global.Values.mariadb "autostart") (not .global.Values.mariadb.autostart) }}
    component: "disabledBecauseOf-mariadb.autostart-disabled"
  {{- else if and (.global.Values.command) (hasKey .global.Values.command "database") }}
    component: "disabledBecauseOf-command.database-defined"
  {{- else if and (hasKey .global.Values.mariadb "wipeDataAndLog") (.global.Values.mariadb.wipeDataAndLog) }}
    component: "disabledBecauseOf-mariadb.wipeDataAndLog-enabled"
  {{- else if and (hasKey .global.Values.mariadb.galera.restore "kopia") (.global.Values.mariadb.galera.restore.kopia.enabled) }}
    component: "disabledBecauseOf-mariadb.galera.restore-enabled"
  {{- else if eq .component "database-direct" }}
    component: "database"
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
  {{- if and (.global.Values.mariadb.galera.multiRegion.enabled) (eq .type "backend") (eq .component "database") (ne .service.type "LoadBalancer") (eq .replica "notused") }}
  externalIPs:
    {{- if and (hasKey .global.Values "global") (hasKey .global.Values.global "db_region") (.global.Values.global.db_region) }}
  - {{ (index .global.Values.mariadb.galera.multiRegion.regions .global.Values.global.db_region).externalIP }}
    {{- else }}
  - {{ (index .global.Values.mariadb.galera.multiRegion.regions (required "mariadb.galera.multiRegion.current has to be defined if the multiRegion parameter is enabled" .global.Values.mariadb.galera.multiRegion.current)).externalIP }}
    {{- end }}
  {{- end }}
  {{- if and (.global.Values.mariadb.galera.multiRegion.enabled) (eq .type "backend") (eq .component "database") (eq .service.type "LoadBalancer") (eq .replica "notused") }}
    {{- if and (hasKey .global.Values "global") (hasKey .global.Values.global "db_region") (.global.Values.global.db_region) }}
  loadBalancerIP: {{ (index .global.Values.mariadb.galera.multiRegion.regions .global.Values.global.db_region).externalIP }}
    {{- else }}
  loadBalancerIP: {{ (index .global.Values.mariadb.galera.multiRegion.regions (required "mariadb.galera.multiRegion.current has to be defined if the multiRegion parameter is enabled" .global.Values.mariadb.galera.multiRegion.current)).externalIP }}
    {{- end }}
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
  {{- if and (hasKey .Values.mariadb.galera "clustername") (.Values.mariadb.galera.clustername) (hasKey .Values.namePrefix "includeClusterName") (.Values.namePrefix.includeClusterName) }}
    {{- printf "%s-%s" $.Release.Name .Values.mariadb.galera.clustername }}
  {{- else }}
    {{- printf "%s" $.Release.Name }}
  {{- end }}
{{- end }}


{{/*
  Fetch current node name prefix for a component (currently database and proxy are supported)
  database node name prefix:   include "nodeNamePrefix" (dict "global" $ "component" "database")
  proxysql node name prefix:      include "nodeNamePrefix" (dict "global" $ "component" "proxysql")
*/}}
{{- define "nodeNamePrefix" }}
  {{- if eq .component "database" }}
    {{- if and (.global.Values.namePrefix) (hasKey .global.Values.namePrefix .component) }}
      {{- printf "%s-%s" (include "commonPrefix" .global) (.global.Values.namePrefix.database | default "mariadb-g") }}
    {{- else }}
      {{- printf "%s-%s" (include "commonPrefix" .global) "mariadb-g" }}
    {{- end }}
  {{- else if eq .component "proxysql" }}
    {{- if and (.global.Values.namePrefix.proxy) (hasKey .global.Values.namePrefix.proxy .component) }}
      {{- printf "%s-%s" (include "commonPrefix" .global) (.global.Values.namePrefix.proxy.proxysql | default "proxysql") }}
    {{- else }}
      {{- printf "%s-%s" (include "commonPrefix" .global) "proxysql" }}
    {{- end }}
  {{- else if eq .component "kopiaserver" }}
    {{- if and (.global.Values.namePrefix) (hasKey .global.Values.namePrefix .component) }}
      {{- printf "%s-%s" (include "commonPrefix" .global) (.global.Values.namePrefix.kopiaserver | default "backup-kopiaserver") }}
    {{- else }}
      {{- printf "%s-%s" (include "commonPrefix" .global) "backup-kopiaserver" }}
    {{- end }}
  {{- else if eq .component "haproxy" }}
    {{- if and (.global.Values.namePrefix.proxy) (hasKey .global.Values.namePrefix.proxy .component) }}
      {{- printf "%s-%s" (include "commonPrefix" .global) (.global.Values.namePrefix.proxy.haproxy | default "haproxy") }}
    {{- else }}
      {{- printf "%s-%s" (include "commonPrefix" .global) "haproxy" }}
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
  {{- $galeraPort := ((required ".services.database.backend.ports.galera.targetPort missing" $.global.Values.services.database.backend.ports.galera.port) | int) }}
  {{- $nodeNames := list -}}
  {{- $nodeNamePrefix := (include "nodeNamePrefix" (dict "global" .global "component" "database")) -}}
  {{- range $int, $err := until ((include "replicaCount" (dict "global" .global "type" "database")) | int) }}
    {{- $nodeNames = (printf "%s-%d.%s:%d" $nodeNamePrefix $int $.global.Release.Namespace $galeraPort) | append $nodeNames -}}
  {{- end }}
  {{- if $.global.Values.mariadb.galera.multiRegion.enabled }}
    {{- $nodeNames := list -}}
    {{- range $regionKey, $regionValue := $.global.Values.mariadb.galera.multiRegion.regions }}
        {{- if or (and (hasKey $.global.Values "global") (hasKey $.global.Values.global "db_region") (ne $.global.Values.global.db_region $regionKey)) (ne $.global.Values.mariadb.galera.multiRegion.current $regionKey) }}
        {{- $nodeNames = (printf "%s:%d" $regionValue.externalIP $galeraPort) | append $nodeNames -}}
      {{- end }}
    {{- end }}
  {{- (printf "gcomm://%s" (join "," $nodeNames)) }}
  {{- else }}
  {{- (printf "gcomm://%s,%s-backend.%s:%d" (join "," $nodeNames) $nodeNamePrefix $.global.Release.Namespace $galeraPort) }}
  {{- end }}
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
  include "getNetworkPort" (dict "global" $ "type" "backend" "component" "database" "name" "ist")
*/}}
{{- define "getNetworkPort" }}
  {{- $service := index $.global.Values.services .component -}}
  {{- $serviceType := index $service .type -}}
  {{- $servicePort := index $serviceType.ports .name -}}
  {{- ($servicePort.port | int) }}
{{- end }}

{{/*
  Generate server-id list value
  include "serverIdList" (dict "global" $)
*/}}
{{- define "serverIdList" }}
  {{- $serverIds := list -}}
  {{- range $int, $err := until ((include "replicaCount" (dict "global" .global "type" "database")) | int) }}
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
  include "generateSecret" (dict "global" $ "name" $credentialKey "credential" $credentialValue "suffix" "mariadb" "type" "secret type")
  include "generateSecret" (dict "global" $ "name" $credentialKey "credential" $credentialValue "type" "basic-auth/Opaque/Dockerconfigjson")
*/}}
{{- define "generateSecret" }}
  {{- if eq $.type "basic-auth" }}
    {{- include "generateSecretTypeBasicAuth" (dict "global" .global "name" $.name "credential" $.credential "suffix" $.suffix) }}
  {{- end }}
  {{- if eq $.type "Opaque" }}
    {{- include "generateSecretTypeOpaque" (dict "global" .global "name" $.name "credential" $.credential "suffix" $.suffix) }}
  {{- end }}
  {{- if eq $.type "Dockerconfigjson" }}
    {{- include "generateSecretTypeDockerconfigjson" (dict "global" .global "name" $.name "credential" $.credential "suffix" $.suffix) }}
  {{- end }}
{{- end }}

{{/*
  Generate Kubernetes basic-auth secrets
  include "generateSecretTypeOpaque" (dict "global" .global "name" $.name "credential" $.credential "suffix" $.suffix)
*/}}
{{- define "generateSecretTypeBasicAuth" }}
---
apiVersion: v1
kind: Secret
type: kubernetes.io/basic-auth
metadata:
  namespace: {{ $.global.Release.Namespace }}
  name: {{ include "commonPrefix" .global }}-{{ $.suffix }}-{{ $.name }}
data:
  username: {{ (required (printf "%s.users.%s.username is required to configure the Kubernetes secret for the '%s' user" $.suffix $.name $.name) $.credential.username) | b64enc }}
  password: {{ (required (printf "%s.users.%s.password is required to configure the Kubernetes secret for the '%s' user" $.suffix $.name $.name) $.credential.password) | b64enc }}
{{- end }}

{{/*
  Generate Kubernetes Opaque secrets
  include "generateSecretTypeOpaque" (dict "global" .global "name" $.name "credential" $.credential "suffix" $.suffix)
*/}}
{{- define "generateSecretTypeOpaque" }}
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  namespace: {{ $.global.Release.Namespace }}
  name: {{ include "commonPrefix" .global }}-{{ $.suffix }}-{{ $.name }}
data:
  password: {{ (required (printf "%s.users.%s.password is required to configure the Kubernetes secret for the '%s' user" $.suffix $.name $.name) $.credential.password) | b64enc }}
{{- end }}

{{/*
  Generate Kubernetes secret kind structure
  include "generateSecretKindDockerconfigjson" (dict "global" .global "name" $.name "credential" $.credential "suffix" $.suffix)
*/}}
{{- define "generateSecretTypeDockerconfigjson" }}
---
apiVersion: v1
kind: Secret
type: kubernetes.io/dockerconfigjson
metadata:
  namespace: {{ $.global.Release.Namespace }}
  name: {{ include "commonPrefix" .global }}-pullsecret-{{ $.name }}
data:
  .dockerconfigjson: {{ printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" (required (printf "image.pullSecrets.%s.registry is required to configure the Kubernetes pull secret '%s'" $.name $.name) $.credential.registry) (printf "%s" (required (printf "image.pullSecrets.%s.credential is required to configure the Kubernetes pull secret '%s'" $.name $.name) $.credential.credential) | b64enc) | b64enc }}
{{- end }}

{{/*
  calculate the effective number of replicas (database/proxy)
  include "replicaCount" (dict "global" $ "type" "database")
*/}}
{{- define "replicaCount" }}
  {{- if $.global.Values.mariadb.galera.multiRegion.enabled }}
    {{- printf "%d" 1 -}}
  {{- else }}
    {{- index $.global.Values.replicas $.type -}}
  {{- end }}
{{- end }}

{{- define "sharedservices.labels" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Chart.Name }}-{{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}
app.kubernetes.io/component: MariaDB-Galera
app.kubernetes.io/part-of: {{ .Release.Name }}
{{- end }}