key "tsig-key" {
    algorithm algorithm "{{ $.Values.tsig_key_algorithm | default "hmac-md5" }}";
    secret "{{ tpl $.Values.tsig_key $ | include "resolve_secret" }}";
};
