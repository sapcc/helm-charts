{{/*
neutron-linuxbridge-agent.volumes renders the pod-level volume entries the
consumer splices into spec.volumes. Call as:

  volumes:
    {{- include "neutron-linuxbridge-agent.volumes" (dict "root" . "values" .Values.linuxbridge_agent) | nindent 4 }}

Two modes:
  - .values.configMap.name set    → mount that ConfigMap (Mode A: BYO)
  - .values.configMap.name empty  → mount the library-rendered ConfigMap
                                    {{ .Release.Name }}-linuxbridge-agent-etc
                                    (consumer must include configmap-etc to
                                    actually create it).
*/}}
{{- define "neutron-linuxbridge-agent.volumes" -}}
- name: linuxbridge-agent-etc
  configMap:
    name: {{ dig "configMap" "name" (printf "%s-linuxbridge-agent-etc" .root.Release.Name) .values }}
- name: modules
  hostPath:
    path: /lib/modules
{{- with .values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}
