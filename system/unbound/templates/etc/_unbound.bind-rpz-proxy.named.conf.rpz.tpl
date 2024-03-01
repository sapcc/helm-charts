{{- define "unbound.bind-rpz-proxy.named.conf.rpz" }}
primaries primaries {
{{- range $rpz_prim := .Values.unbound.rpz.primaries }}
  {{ $rpz_prim }} key {{ $.Values.unbound.rpz.tsig.keyname | quote }};
{{- end }}
};

{{- range $rpz_zone := .Values.unbound.rpz.zones }}
zone {{ $rpz_zone | quote }} {
  type secondary;
  primaries { primaries; };
};
{{- end }}
{{- end }}
