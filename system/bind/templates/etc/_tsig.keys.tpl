{{- if $.Values.tsig }}
key "{{ $.Values.tsig.keyname }}" {
    algorithm "{{ $.Values.tsig.algo }}";
    secret "{{ $.Values.tsig.secret }}";
};
{{- else }}
key "{{ tpl ( $.Values.tsig_key_name | default "tsig-key" ) $ }}" {
    algorithm "{{ tpl ( $.Values.tsig_key_algorithm | default "hmac-md5" ) $ | include "resolve_secret" }}";
    secret "{{ tpl $.Values.tsig_key $ | include "resolve_secret" }}";
};
{{- end }}

{{- if $.Values.allow_transfer }}
{{- range $tsig := $.Values.allow_transfer.tsig }}
key "{{ $tsig.keyname }}" {
    algorithm "{{ $tsig.algo }}";
    secret "{{ $tsig.secret }}";
};
{{- end }}
{{- end }}
