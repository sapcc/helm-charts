{{/*
neutron-agents.linuxbridge.container renders the neutron-linuxbridge-agent
container spec, ready to splice into a Pod's containers: list. Call as:

  containers:
    {{- include "neutron-agents.linuxbridge.container" (dict "root" . "values" .Values.linuxbridge_agent) | nindent 4 }}

The image, config volume mounts, and neutron.conf plumbing come from the shared
helpers in _helpers.tpl; only the agent name, command, capabilities, and the
/lib/modules mount are linuxbridge-specific. A metadata/dhcp sibling would
define its own container define reusing the same shared helpers.
*/}}
{{- define "neutron-agents.linuxbridge.container" -}}
- name: neutron-linuxbridge-agent
  image: {{ include "neutron-agents.image" . }}
  imagePullPolicy: IfNotPresent
  command:
    - neutron-linuxbridge-agent
    {{- range .values.extraConfigs }}
    - --config-file
    - {{ . }}
    {{- end }}
    {{- range .values.extraConfigDirs }}
    - --config-dir
    - {{ . }}
    {{- end }}
  securityContext:
    runAsUser: 0
    # Must be a superset of neutron's oslo.privsep default context + SETPCAP, or the privsep daemon fails to start.
    capabilities:
      add:
        - NET_ADMIN
        - SYS_ADMIN
        - SETPCAP
        - DAC_OVERRIDE
        - DAC_READ_SEARCH
        - SYS_PTRACE
  envFrom:
    - secretRef:
        name: {{ required ".values.secretName is required" .values.secretName }}
  {{- with .values.extraEnv }}
  env:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .values.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    {{- include "neutron-agents.configVolumeMounts" (merge (dict "volumeName" "linuxbridge-agent-etc") .) | nindent 4 }}
    - name: modules
      mountPath: /lib/modules
      readOnly: true
    {{- with .values.extraVolumeMounts }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
{{- end -}}
