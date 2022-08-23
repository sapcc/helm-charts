{{/*
  Generate Kubernetes service template
  service without per pod information:  include "networkService" (dict "global" $ "service" $service "component" $component "replica" "notused")
  service with per pod information:     include "networkService" (dict "global" $ "service" $service "component" $component "replica" ($replicaNumber|toString))
*/}}
{{- define "networkService" }}
{{- $nodeNamePrefix := "" -}}
{{- $nodeNamePrefixApplication := "" -}}
{{- $nodeNamePrefixProxy := "" -}}
{{ if and (.global.Values.namePrefix) (hasKey .global.Values.namePrefix "application") }}
  {{- $nodeNamePrefixApplication = (.global.Values.namePrefix.application | default "mariadb-g") }}
{{ else }}
  {{- $nodeNamePrefixApplication = "mariadb-g" }}
{{ end }}
{{ if and (.global.Values.namePrefix) (hasKey .global.Values.namePrefix "proxy") }}
  {{- $nodeNamePrefixProxy = (.global.Values.namePrefix.application | default "proxysql") }}
{{ else }}
  {{- $nodeNamePrefixProxy = "proxysql" }}
{{ end }}

{{- if eq .component "application" }}
  {{- $nodeNamePrefix = $nodeNamePrefixApplication }}
{{- else if eq .component "proxy" }}
  {{- $nodeNamePrefix = $nodeNamePrefixProxy }}
{{ end }}
---
apiVersion: v1
kind: Service
metadata:
  namespace: {{ .global.Release.Namespace }}
  {{- if eq .replica "notused" }}
    {{- if and (eq .service.value.name "frontend") (.global.Values.proxy.enabled)}}
  name: {{ (printf "%s-%s" $nodeNamePrefixApplication .service.value.name) }}
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
    component: {{ .component | quote }}
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