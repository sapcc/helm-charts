key "tsig-key" {
    algorithm hmac-md5;
    secret {{ tpl $.Values.tsig_key $ | include "resolve_secret" | quote }};
};
