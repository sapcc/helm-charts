key "nsi-key" {
    algorithm hmac-sha512;
    secret "{{ .Values.nsi_key | include "resolve_secret" }}";
};
