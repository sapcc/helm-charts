{{/*
neutron-linuxbridge-agent.configmap-etc renders a full ConfigMap resource.
Call from a consumer template, e.g.:

  {{- include "neutron-linuxbridge-agent.configmap-etc" (dict "root" . "values" .Values.linuxbridge_agent) }}
*/}}
{{- define "neutron-linuxbridge-agent.configmap-etc" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .root.Release.Name }}-linuxbridge-agent-etc
data:
  neutron.conf: |
    {{- include "neutron-linuxbridge-agent.neutron-conf" . | nindent 4 }}
  logging.conf: |
    {{- include "neutron-linuxbridge-agent.logging-conf" . | nindent 4 }}
{{- end -}}
