{{/*
Shared helpers reused by every neutron agent in this library. Agent-specific
templates (neutron-agents.<agent>.container, .volumes, .configmap-etc,
.neutron-conf) live in their own files and call into these.

All helpers take the (dict "root" . "values" <agent-subtree>) shape, matching
the agent-facing templates, so a consumer only ever constructs that dict once.
*/}}

{{/*
neutron-agents.image resolves the loci-neutron image reference shared by all
neutron agents. The version cascades through the agent-local override and then
the umbrella chart's conventional keys.

  {{ include "neutron-agents.image" (dict "root" . "values" .Values.linuxbridge_agent) }}
    -> registry.example.com/loci-neutron:caracal
*/}}
{{- define "neutron-agents.image" -}}
{{- $registry := .root.Values.global.registry | required ".Values.global.registry is required" -}}
{{- $version := .values.imageVersion
    | default .root.Values.imageVersionNetworkAgentLinuxBridge
    | default .root.Values.imageVersionNetworkAgent
    | default .root.Values.imageVersion
    | required "Set imageVersionNetworkAgentLinuxBridge, imageVersionNetworkAgent, or imageVersion" -}}
{{- printf "%s/loci-neutron:%s" $registry $version -}}
{{- end -}}

{{/*
neutron-agents.configVolume renders the pod-level ConfigMap volume that every
agent mounts its neutron.conf / logging.conf from. Two modes:
  - .values.configMap.name set    → mount that ConfigMap (BYO)
  - .values.configMap.name empty  → mount the library-rendered ConfigMap named
                                     {{ .Release.Name }}-<defaultName>

Inputs: root, values, plus:
  volumeName   name of the pod volume (e.g. linuxbridge-agent-etc)
  defaultName  ConfigMap name suffix when the library renders it
*/}}
{{- define "neutron-agents.configVolume" -}}
- name: {{ .volumeName }}
  configMap:
    name: {{ dig "configMap" "name" "" .values | default (printf "%s-%s" .root.Release.Name .defaultName) }}
{{- end -}}

{{/*
neutron-agents.configVolumeMounts renders the neutron.conf + logging.conf
volumeMounts shared by every agent. Inputs: root, values, plus volumeName.
*/}}
{{- define "neutron-agents.configVolumeMounts" -}}
- name: {{ .volumeName }}
  mountPath: /etc/neutron/neutron.conf
  subPath: {{ dig "configMap" "key" "neutron.conf" .values }}
  readOnly: true
- name: {{ .volumeName }}
  mountPath: /etc/neutron/logging.conf
  subPath: {{ dig "configMap" "loggingKey" "logging.conf" .values }}
  readOnly: true
{{- end -}}
