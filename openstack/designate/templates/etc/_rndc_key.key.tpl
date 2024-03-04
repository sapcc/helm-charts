{{- range $rndc := .Values.rndc_keys }}
key "{{ $rndc.name }}" {
  algorithm "{{ $rndc.algorithm }}";
  secret "{{ $rndc.secret }}";
};
{{- end }}
