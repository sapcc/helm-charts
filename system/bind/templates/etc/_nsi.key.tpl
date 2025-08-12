key "nsi-key" {
    algorithm hmac-sha512;
    secret {{ tpl $.Values.nsi_key $ | include "resolve_secret" | quote }};
};
