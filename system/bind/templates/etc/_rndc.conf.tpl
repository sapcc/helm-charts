{{- if .Values.rndc }}
controls {
  inet * allow { {{ .Values.rndc_allow }} } keys { {{ range $rndc := .Values.rndc }} {{ $rndc.keyname }}; {{ end }} };
};
{{- else }}
controls {
  inet * allow { {{ .Values.rndc_allow }} } keys { {{ tpl ( $.Values.rndc_key_name | default "rndc-key" ) $ }}; };
};
{{- end }}

include "/etc/bind/rndc.keys";
include "/etc/bind/rndc.key";
