{{- if or (eq .Values.global.region "qa-de-1") (eq .Values.global.region "qa-de-2") }}
log-queries
log-facility=/var/log/dnsmasq.log
{{- end }}
no-negcache
