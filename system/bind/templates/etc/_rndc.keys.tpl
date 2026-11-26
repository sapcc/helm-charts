{{- range $rndc := .Values.rndc }}
key "{{ $rndc.keyname }}" {
    algorithm "{{ $rndc.algo }}";
    secret "{{ $rndc.secret }}";
};
{{- end }}
