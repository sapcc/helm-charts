{{/*
  Generate Kubernetes service template
  service without per pod information:  include "networkService" (dict "global" $ "service" $service "component" $component "replica" "notused")
  service with per pod information:     include "networkService" (dict "global" $ "service" $service "component" $component "replica" ($replicaNumber|toString))
*/}}
{{- define "networkService" }}
{{ $nodeNamePrefix := "" }}
{{ if or (eq .component "application") (eq .component "application-direct") }}
  {{ $nodeNamePrefix = (include "nodeNamePrefix" (dict "global" .global "component" "application")) }}
{{ else if eq .component "proxy" }}
  {{ $nodeNamePrefix = (include "nodeNamePrefix" (dict "global" .global "component" "proxy")) }}
{{ end }}
---
apiVersion: v1
kind: Service
metadata:
  namespace: {{ .global.Release.Namespace }}
  {{- if eq .replica "notused" }}
    {{- if and (eq .service.value.name "frontend") (.global.Values.proxy.enabled) (eq .component "proxy")}}
  name: {{ (printf "%s-%s" (include "nodeNamePrefix" (dict "global" .global "component" "application")) .service.value.name) }}
    {{- else if and (eq .service.value.name "frontend") (eq .component "application-direct")}}
  name: {{ (printf "%s-%s-direct" $nodeNamePrefix .service.value.name) }}
    {{- else }}
  name: {{ (printf "%s-%s" $nodeNamePrefix .service.value.name) }}
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
  type: {{ required "the network service type has to be defined" .service.value.type }}
  {{- if .service.value.headless }}
  clusterIP: None
  publishNotReadyAddresses: true {{/* create A records for not ready pods and announce the IPs on the headless service before they are ready https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-hostname-and-subdomain-fields */}}
  {{- end }}
  selector:

  {{- if eq .replica "notused" }}
    {{- if eq .component "application-direct" }}
    component: "application"
    {{- else }}
    component: {{ .component | quote }}
    {{- end }}
  {{- else }}
    statefulset.kubernetes.io/pod-name: {{ (printf "%s-%s" $nodeNamePrefix .replica) }}
  {{- end }}
  ports:
  {{- range $portKey, $portValue := .service.value.ports }}
    - name: {{ $portValue.name }}
      port: {{ $portValue.port }}
      targetPort: {{ $portValue.targetPort }}
      protocol: {{ $portValue.protocol | default "TCP" }}
  {{- end }}
  sessionAffinity: {{ .service.value.sessionAffinity | default "None" | quote }}
{{- end }}

{{/*
  Fetch current node name prefix for a component (currently application and proxy are supported)
  application node name prefix:   include "nodeNamePrefix" (dict "global" $ "component" "application")
  proxy node name prefix:         include "nodeNamePrefix" (dict "global" $ "component" "proxy")
*/}}
{{- define "nodeNamePrefix" }}
  {{- if eq .component "application" }}
    {{- if and (.global.Values.namePrefix) (hasKey .global.Values.namePrefix .component) }}
      {{- (.global.Values.namePrefix.application | default "mariadb-g") }}
    {{- else }}
      {{- "mariadb-g" }}
    {{- end }}
  {{- else if eq .component "proxy" }}
    {{- if and (.global.Values.namePrefix) (hasKey .global.Values.namePrefix .component) }}
      {{- (.global.Values.namePrefix.proxy | default "proxysql") }}
    {{- else }}
      {{- "proxysql" }}
    {{- end }}
  {{- else }}
    {{- fail "No supported component provided for the nodeNamePrefix function" }}
  {{- end }}
{{- end }}