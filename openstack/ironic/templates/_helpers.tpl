{{ define "ironic.pxe_setup_script" }}
cd /tftpboot

if [ ! -f lpxelinux.0 ]; then
  [ -z "$a" ] && apt-get update && a=1
  apt-get install pxelinux
  cp /usr/lib/PXELINUX/* .
fi

if [ ! -f ldlinux.c32 ]; then
  [ -z "$a" ] && apt-get update && a=1
  apt-get install syslinux-common
  cp /usr/lib/syslinux/modules/*/ldlinux.* .
fi

{{- range $v, $url := .Values.tftp_files }}
curl -sRz {{ $v }} -o {{ $v }} {{ $url }}
{{- end }}

chown -R ironic:ironic .
{{ end }}

{{- define "ironic.job_metadata" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
labels:
  alert-tier: os
  alert-service: {{ .Chart.Name }}
{{ tuple . .Release.Name $name | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 2 }}
annotations:
  bin-hash: {{ include (print .Template.BasePath "/bin/_" $name ".tpl") . | sha256sum }}
  {{- end }}
{{- end }}

{{- define "ironic.job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $bin := include (print .Template.BasePath "/bin/_" $name ".tpl") . }}
    {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) | join "\n" }}
    {{- $hash := empty .Values.proxysql.mode | ternary $bin $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.imageVersion | required "Please set imageVersion or similar"}}
  {{- end }}
{{- end }}

