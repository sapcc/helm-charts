key "tsig-key" {
    algorithm hmac-md5;
    secret "{{ .Values.tsig_key }}";
};
