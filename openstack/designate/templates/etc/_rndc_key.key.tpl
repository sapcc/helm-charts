{{- range $rndc := .Values.rndc_keys }}
key '{{ $rndc.name }}' {
  algorithm '{{ $rndc.algorithm }}';
  secret '{{ $rndc.secret | include "resolve_secret" }}';
};
{{- end }}
