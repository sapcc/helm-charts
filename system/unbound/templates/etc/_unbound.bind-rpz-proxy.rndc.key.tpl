{{- define "unbound.bind-rpz-proxy.rndc.key" }}
key {{ default "rndc-key" .Values.unbound.bind_rpz_proxy.rndc.keyname | quote }} {
  algorithm {{ default "hmac-sha512" .Values.unbound.bind_rpz_proxy.rndc.algo | quote }};
  secret {{ .Values.unbound.bind_rpz_proxy.rndc.secret | quote }};
};
{{- end }}
