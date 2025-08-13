key "nsi-key" {
    algorithm "{{ $.Values.nsi_key_algorithm | default "hmac-sha512" }}";
    secret "{{ tpl $.Values.nsi_key $ | include "resolve_secret" }}";
};
