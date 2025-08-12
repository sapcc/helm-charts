key {{ $.Values.rndc_key_name | default "rndc-key" | quote }} {
    algorithm {{ $.Values.rndc_key_algorithm | default "hmac-md5" | quote }};
    secret {{ tpl $.Values.rndc_key $ | include "resolve_secret" | quote }};
};
