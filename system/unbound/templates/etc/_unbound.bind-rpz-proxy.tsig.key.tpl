{{- define "unbound.bind-rpz-proxy.tsig.key" }}
key {{ .Values.unbound.rpz.tsig.keyname }} {
  algorithm {{ default "hmac-sha512" .Values.unbound.rpz.tsig.algo }};
  secret {{ .Values.unbound.rpz.tsig.secret }};
};
{{- end }}
