key "{{ tpl ( $.Values.tsig_key_name | default "tsig-key" ) }}" {
    algorithm "{{ tpl ( $.Values.tsig_key_algorithm | default "hmac-md5" ) $ | include "resolve_secret" }}";
    secret "{{ tpl $.Values.tsig_key $ | include "resolve_secret" }}";
};
