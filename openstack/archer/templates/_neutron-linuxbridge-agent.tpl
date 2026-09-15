{{/*
Minimal linuxbridge-agent helpers vendored from the unmerged library branch so
archer can render its own agent config and pod fragments without a chart
dependency.
*/}}

{{- define "archer.neutron-linuxbridge-agent.container" -}}
{{- $registry := .root.Values.global.registry | required ".Values.global.registry is required" -}}
{{- $version := .values.imageVersion | default .root.Values.image.neutron_version | required "Set .Values.image.neutron_version or .Values.linuxbridge_agent.imageVersion" -}}
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
        name: {{ required ".Values.linuxbridge_agent.secretName is required" .values.secretName }}
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
      subPath: neutron.conf
      readOnly: true
    - name: linuxbridge-agent-etc
      mountPath: /etc/neutron/logging.conf
      subPath: logging.conf
      readOnly: true
    - name: modules
      mountPath: /lib/modules
      readOnly: true
    {{- with .values.extraVolumeMounts }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
{{- end -}}

{{- define "archer.neutron-linuxbridge-agent.volumes" -}}
- name: linuxbridge-agent-etc
  configMap:
    name: {{ .root.Release.Name }}-linuxbridge-agent-etc
- name: modules
  hostPath:
    path: /lib/modules
{{- with .values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "archer.neutron-linuxbridge-agent.configmap-etc" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .root.Release.Name }}-linuxbridge-agent-etc
data:
  neutron.conf: |
    {{- include "archer.neutron-linuxbridge-agent.neutron-conf" . | nindent 4 }}
  logging.conf: |
    {{- include "archer.neutron-linuxbridge-agent.logging-conf" . | nindent 4 }}
{{- end -}}

{{- define "archer.neutron-linuxbridge-agent.neutron-conf" -}}
[DEFAULT]
core_plugin = ml2
debug = {{ .values.debug | default false }}
log_config_append = /etc/neutron/logging.conf
default_log_levels = {{ join "," (.values.default_log_levels | default (list "neutron.plugins.ml2.drivers.agent._common_agent=WARN")) }}
{{- with .values.host }}
host = {{ . }}
{{- end }}

[agent]
polling_interval = {{ dig "agent" "polling_interval" 2 .values }}

[linux_bridge]
# physical_interface_mappings comes from env OS_LINUX_BRIDGE__PHYSICAL_INTERFACE_MAPPINGS

[vxlan]
enable_vxlan = {{ dig "vxlan" "enable" false .values }}

[securitygroup]
firewall_driver = {{ dig "securitygroup" "firewall_driver" "iptables" .values }}

[privsep]
thread_pool_size = {{ dig "privsep" "thread_pool_size" 3 .values }}
helper_command = {{ dig "privsep" "helper_command" "privsep-helper --config-file /etc/neutron/neutron.conf" .values }}

{{- $helper := dig "privsep" "helper_command" "privsep-helper --config-file /etc/neutron/neutron.conf" .values }}
{{- range list "privsep_dhcp_release" "privsep_ovs_vsctl" "privsep_namespace" "privsep_conntrack" "privsep_link" }}

[{{ . }}]
helper_command = {{ $helper }}
{{- end }}

[oslo_concurrency]
lock_path = /tmp
{{- end -}}

{{- define "archer.neutron-linuxbridge-agent.logging-conf" -}}
{{- $default := dict
    "loggers" (dict
        "root" (dict "handlers" "stdout" "level" "INFO")
    )
    "handlers" (dict
        "stdout" (dict "class" "StreamHandler" "args" "(sys.stdout,)" "formatter" "context")
    )
    "formatters" (dict
        "context" (dict "class" "oslo_log.formatters.ContextFormatter")
    )
-}}
{{- $logging := .values.logging | default $default -}}
{{- include "loggerIni" $logging -}}
{{- end -}}
