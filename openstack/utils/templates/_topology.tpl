{{/*
  Topology constraints to spread nodes across azs to ensure the
  service being up even in the face of an az being down
*/}}

{{/* "utils.topology.constraints"
  Deployment: .spec.template.spec
  I.e.
  spec:
    {{-  include "utils.topology.constraints" . | indent 2 }}
    */}}
{{- define "utils.topology.constraints" }}
topologySpreadConstraints:
{{- include "utils.topology.az_spread" . }}
{{- end }}

{{/* "utils.topology.pod_label"
  Deployment: .spec.template.metadata.labels
  I.e.
  metadata:
    labels:
      mylabel: myvalue
      {{- include "utils.topology.pod_label" . | indent 4 }}

 The scheduler needs to differentiate between the pods of the
 old replicaset, which is being teared down, and the new one.
 Prior kubernetes 1.27, that needs to be done explicitly, here
 with the .Release.Revision.
*/}}
{{- define "utils.topology.pod_label" }}
  {{- if gt (len .Values.global.availability_zones) 1  }}
    {{- if semverCompare "< 1.27" .Capabilities.KubeVersion.Version }}
release_revision: "{{ .Release.Revision }}"
    {{- end }}
  {{- end }}
{{- end }}

{{/* "utils.topology.az_spread"
  Just the portion for the az-spread, in case it needs
  to be combined with some custom topologySpreadConstraints
  */}}
{{- define "utils.topology.az_spread" }}
{{- $envAll := index . 0 }}
{{- $labels := index . 1 }}
  {{- if gt (len $envAll.Values.global.availability_zones) 1  }}
- maxSkew: 1
  topologyKey: "{{ $envAll.Values.global.topology_key | default "failure-domain.beta.kubernetes.io/zone" }}"
  whenUnsatisfiable: ScheduleAnyway
  labelSelector:
    matchLabels:
    {{- range $k, $v := $labels }}
      {{ $k }}: "{{ $v }}"
    {{- end }}
    {{- if semverCompare "< 1.27" $envAll.Capabilities.KubeVersion.Version }}
      release_revision: "{{ $envAll.Release.Revision }}"
    {{- else }}
  matchLabelKeys:
    - pod-template-hash
    {{- end }}
  {{- end }}
{{- end }}

{{/* "utils.topology.service_topology_mode"
  Enables topology aware routing
  */}}
{{- define "utils.topology.service_topology_mode" }}
  {{- if gt (len .Values.global.availability_zones) 1  }}
    {{- if semverCompare "< 1.27" .Capabilities.KubeVersion.Version }}
  service.kubernetes.io/topology-aware-hints: "Auto"
    {{- else }}
  service.kubernetes.io/topology-mode: "Auto"
    {{- end }}
  {{- end }}
{{- end }}
