{{- /* Render DEFAULT options and additional INI sections without outer blank lines. */ -}}
{{- define "nova.hypervisor.conf" -}}
  {{- $sections := list }}
  {{- with . }}
    {{- if .default }}
      {{- $lines := list "[DEFAULT]" }}
      {{- range $k, $v := .default }}
        {{- $lines = append $lines (printf "%s = %v" $k $v) }}
      {{- end }}
      {{- $sections = append $sections (join "\n" $lines) }}
    {{- end }}
    {{- if .config_file }}
      {{- $sections = append $sections (include "util.helpers.valuesToIni" .config_file | trim) }}
    {{- end }}
  {{- end }}
  {{- join "\n\n" $sections }}
{{- end -}}

{{- /* Parameters: (root context, hypervisor config). */ -}}
{{- define "nova.hypervisor.console.conf" -}}
  {{- $root := index . 0 }}
  {{- $sections := list }}
  {{- with index . 1 }}
    {{- $cell := include "nova.helpers.cell_name" (tuple $root (include "nova.helpers.get_active_cell" $root)) }}
    {{- if and .vnc (hasKey .vnc "enabled") }}
      {{- $sections = append $sections (tuple $root $cell .vnc | include "console-novnc.conf" | trim) }}
    {{- end }}
    {{- if and .serial (hasKey .serial "enabled") }}
      {{- $sections = append $sections (tuple $root $cell .serial | include "console-serial.conf" | trim) }}
    {{- end }}
  {{- end }}
  {{- join "\n\n" $sections }}
{{- end -}}

{{- define "nova.hypervisor.common.conf" -}}
{{- include "nova.hypervisor.conf" .Values.defaults.hypervisor.common }}
{{- end -}}

{{- define "nova.hypervisor.kvm.conf" -}}
{{- $config := include "nova.hypervisor.conf" .Values.defaults.hypervisor.kvm }}
{{- $console := tuple . .Values.defaults.hypervisor.kvm | include "nova.hypervisor.console.conf" }}
{{- list $config $console | compact | join "\n\n" }}
{{- end -}}

{{- define "nova.hypervisor.instance.conf" -}}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- $hv := index . 2 }}
{{- $comment := printf "# Hypervisor instance overrides for %s" $name }}
{{- $config := include "nova.hypervisor.conf" $hv }}
{{- $console := tuple $root $hv | include "nova.hypervisor.console.conf" }}
{{- list $comment $config $console | compact | join "\n\n" }}
{{- end -}}
