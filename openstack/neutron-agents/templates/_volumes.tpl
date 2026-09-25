{{/*
neutron-agents.linuxbridge.volumes renders the pod-level volume entries the
consumer splices into spec.volumes. Call as:

  volumes:
    {{- include "neutron-agents.linuxbridge.volumes" (dict "root" . "values" .Values.linuxbridge_agent) | nindent 4 }}

The linuxbridge-agent-etc ConfigMap volume is wired by the shared
neutron-agents.configVolume helper. Two modes:
  - .values.configMap.name set    → mount that ConfigMap (Mode A: BYO)
  - .values.configMap.name empty  → mount the library-rendered ConfigMap
                                    {{ .Release.Name }}-linuxbridge-agent-etc
                                    (consumer must include configmap-etc to
                                    actually create it).

The modules hostPath is linuxbridge-specific (the agent verifies bridge/vxlan
kernel modules) and stays here rather than in the shared helper.
*/}}
{{- define "neutron-agents.linuxbridge.volumes" -}}
{{- include "neutron-agents.configVolume" (merge (dict "volumeName" "linuxbridge-agent-etc" "defaultName" "linuxbridge-agent-etc") .) }}
- name: modules
  hostPath:
    path: /lib/modules
{{- with .values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}
