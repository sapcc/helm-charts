{{- define "ironic_conductor_conf" -}}
{{- $envAll    :=  index . 0 -}}
{{- $conductor :=  index . 1 -}}
{{- with $envAll -}}
{{- $tftp_ip :=  $conductor.tftp_ip | default .Values.tftp_ip | default .Values.global.ironic_tftp_ip }}
{{- $deploy_port :=  $conductor.tftp_ip | default .Values.tftp_ip | default .Values.global.ironic_tftp_ip }}
[DEFAULT]
host = ironic-conductor-{{$conductor.name}}
{{- if $conductor.enabled_drivers }}
enabled_drivers = {{ $conductor.enabled_drivers}}
{{- end }}
{{- range $k, $v :=  $conductor.default }}
{{ $k }} = {{ $v }}
{{- end }}

[agent]
{{- range $k, $v :=  $conductor.agent }}
{{ $k }} = {{ $v }}
{{- end }}

[conductor]
{{- range $k, $v :=  $conductor.conductor }}
{{ $k }} = {{ $v }}
{{- end }}

[console]
terminal_pid_dir = /shellinabox
terminal_url_scheme = https://{{ include "ironic_console_endpoint_host_public" . }}/{{$conductor.name}}/%(uuid)s/%(expiry)s/%(digest)s
socket_permission = 0666
ssh_command_pattern = sshpass -f %(pw_file)s ssh -oLogLevel={{ .Values.console.ssh_loglevel | default "error" }} -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -oKexAlgorithms=+diffie-hellman-group1-sha1 -c 'aes128-cbc','aes256-cbc','3des-cbc' -l %(username)s %(address)s
url_auth_digest_secret = {{required "A valid .Values.console.secret required!" .Values.console.secret}}

[deploy]
# We expose this directory over http and tftp
http_root = /tftpboot
http_url = {{ .Values.conductor.deploy.protocol }}://{{ $tftp_ip }}:{{ .Values.conductor.deploy.port }}/tftpboot
{{- range $k, $v :=  $conductor.deploy }}
{{ $k }} = {{ $v }}
{{- end }}

[dhcp]
{{- range $k, $v :=  $conductor.dhcp }}
{{ $k }} = {{ $v }}
{{- end }}

[pxe]
tftp_server = {{ $tftp_ip }}
tftp_root = /tftpboot

{{- range $k, $v :=  $conductor.pxe }}
{{ $k }} = {{ $v }}
{{- end }}

{{- if $conductor.pxe.ipxe_enabled }}
pxe_config_template = /etc/ironic/ipxe_config.template
{{- else }}
pxe_config_template = /etc/ironic/pxe_config.template
{{- end }}
uefi_pxe_bootfile_name = ipxe.efi
uefi_pxe_config_template = /etc/ironic/ipxe_config.template

{{- if $conductor.jinja2 }}
{{`
{%- for section in block %}
{%- if block[section] is mapping %}

[{{ section }}]
{%- for k in block[section] %}
{{ k }} = {{ block[section][k] }}
{%- endfor %}
{%- endif %}
{%- endfor %}
`}}
{{- end }}
{{- end }}
{{- end }}
