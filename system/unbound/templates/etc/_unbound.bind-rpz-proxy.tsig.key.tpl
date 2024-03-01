{{- define "unbound.bind-rpz-proxy.tsig.key" }}
key {{ .Values.unbound.rpz.tsig.keyname | quote }} {
  algorithm {{ default "hmac-sha512" .Values.unbound.rpz.tsig.algo | quote }};
  secret {{ .Values.unbound.rpz.tsig.secret | quote }};
};
{{- end }}
