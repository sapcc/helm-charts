{{/*
  Generate Kubernetes service template
  service without per pod information:  include "networkService" (dict "global" $ "service" $service "replica" "notused")
  service with per pod information:     include "networkService" (dict "global" $ "service" $service "replica" ($replicaNumber|toString))
*/}}
{{- define "networkService" }}
---
apiVersion: v1
kind: Service
metadata:
  namespace: {{ .global.Release.Namespace }}
  {{- if eq .replica "notused" }}
  name: {{ .global.Release.Name }}-{{ .service.value.name }}
  {{- else }}
  name: g{{ .replica }}
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
  publishNotReadyAddresses: true #create A records for not ready pods and announce the IPs on the headless service before they are ready https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-hostname-and-subdomain-fields
  {{- end }}
  selector:
  {{- if eq .replica "notused" }}
    app: {{ .global.Release.Name }}
  {{- else }}
    statefulset.kubernetes.io/pod-name: {{ .global.Release.Name }}-{{ .replica }}
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