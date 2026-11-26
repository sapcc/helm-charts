{{- if .Values.rndc }}
{{- $rndc := index .Values.rndc 0 }}
key "{{ $rndc.keyname }}" {
    algorithm "{{ $rndc.algo }}";
    secret "{{ $rndc.secret }}";
};
{{- else }}
key "{{ tpl ( $.Values.rndc_key_name | default "rndc-key" ) $ }}" {
    algorithm "{{ tpl ( $.Values.rndc_key_algorithm | default "hmac-md5" ) $ | include "resolve_secret" }}";
    secret "{{ tpl $.Values.rndc_key $ | include "resolve_secret" }}";
};
{{- end }}
