{{- range $rndc := .Values.rndc_keys }}
key '{{ $rndc.name }}' {
  algorithm '{{ $rndc.algorithm }}';
  secret '{{ include "resolve_secret" $rndc.secret }}';
};
{{- end }}
