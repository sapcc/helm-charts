key "nsi-key" {
    algorithm "{{ tpl ( $.Values.nsi_key_algorithm | default "hmac-sha512" ) $ | include "resolve_secret" }}";
    secret "{{ tpl $.Values.nsi_key $ | include "resolve_secret" }}";
};
