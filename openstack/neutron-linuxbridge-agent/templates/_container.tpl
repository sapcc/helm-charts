{{/*
neutron-linuxbridge-agent.container renders one container spec ready to splice
into a Pod's containers: list. Call as:

  containers:
    {{- include "neutron-linuxbridge-agent.container" (dict "root" . "values" .Values.linuxbridge_agent) | nindent 4 }}
*/}}
{{- define "neutron-linuxbridge-agent.container" -}}
{{- $registry := .root.Values.global.registry | required ".Values.global.registry is required" -}}
{{- $version := .values.imageVersion
    | default .root.Values.imageVersionNetworkAgentLinuxBridge
    | default .root.Values.imageVersionNetworkAgent
    | default .root.Values.imageVersion
    | required "Set imageVersionNetworkAgentLinuxBridge, imageVersionNetworkAgent, or imageVersion" -}}
- name: neutron-linuxbridge-agent
  image: {{ $registry }}/loci-neutron:{{ $version }}
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
    capabilities:
      add:
        - NET_ADMIN
        - SYS_ADMIN
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
    - name: linuxbridge-agent-etc
      mountPath: /etc/neutron/neutron.conf
      subPath: {{ dig "configMap" "key" "neutron.conf" .values }}
      readOnly: true
    - name: linuxbridge-agent-etc
      mountPath: /etc/neutron/logging.conf
      subPath: {{ dig "configMap" "loggingKey" "logging.conf" .values }}
      readOnly: true
    - name: modules
      mountPath: /lib/modules
      readOnly: true
    {{- with .values.extraVolumeMounts }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
{{- end -}}
