{{/*
neutron-agents.linuxbridge.configmap-etc renders a full ConfigMap resource with
the linuxbridge agent's neutron.conf + logging.conf. Call from a consumer
template, e.g.:

  {{- include "neutron-agents.linuxbridge.configmap-etc" (dict "root" . "values" .Values.linuxbridge_agent) }}

logging.conf is rendered by the shared neutron-agents.logging-conf helper;
neutron.conf is the linuxbridge-specific body (which itself starts from the
shared neutron-agents.neutron-conf.common base).
*/}}
{{- define "neutron-agents.linuxbridge.configmap-etc" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .root.Release.Name }}-linuxbridge-agent-etc
data:
  neutron.conf: |
    {{- include "neutron-agents.linuxbridge.neutron-conf" . | nindent 4 }}
  logging.conf: |
    {{- include "neutron-agents.logging-conf" . | nindent 4 }}
{{- end -}}
