{{- define "utils.env.pyroscope" }}
    {{- $envAll := index . 0 -}}
    {{- $application := index . 1 -}}
    {{- with $envAll }}
        {{- $settings := merge (get .Values.pyroscope $application) (dict "app_name" $application) .Values.pyroscope.defaults .Values.utils.pyroscope_defaults }}
        {{- if $settings.enabled }}
            {{- range $k, $v := $settings }}
                {{- if not (eq $k "enabled") }}
- name: PYRO_{{ $k | upper}}
  value: "{{ $v }}"
                {{- end }}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end }}
