{{- define "utils.linkerd.pod_and_service_annotation" }}
{{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested }}
linkerd.io/inject: enabled
{{- end }}
{{- end }}

{{- define "utils.linkerd.ingress_annotation" }}
{{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested }}
ingress.kubernetes.io/service-upstream: "true"
nginx.ingress.kubernetes.io/service-upstream: "true"
{{- end }}
{{- end }}

# Place this in job scripts when your script stops normally, but not abnormally
# as this causes the side-car pod finish normally, but we need it for the re-runs
{{- define "utils.linkerd.signal_stop_script" }}
{{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested }}
if command -v curl > /dev/null; then
  curl -X POST http://localhost:4191/shutdown || true
else
  ( exec 3<>/dev/tcp/localhost/4191 &&
    printf "POST /shutdown HTTP/1.0\r\n\r\n" 1>&3  &&
    cat <&3 || true )
fi
{{- end }}
{{- end }}
