key "{{ .Values.rndc_key_name | default "rndc-key" }}" {
    algorithm "{{ .Values.rndc_key_algorithm | default "hmac-md5" }}";
    secret "{{ .Values.rndc_key }}";
};
