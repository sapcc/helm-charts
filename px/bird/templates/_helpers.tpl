
{{- /*
All bird.domain.* expect a domain-context that should look like the following:
top: the root helm context including .Files, .Release, .Chart, .Values
service: service_1
service_number: 1
service_config: everything nested under .Values.services_1
domain_number: 1
domain_config: everything nested under .Values.service_1.domain_1
*/}}

{{- define "bird.domain.config_name" -}}
{{- printf "%s-pxrs-%d-s%d" .top.Values.global.region .domain_number .service_number }}
{{- end }}

{{- define "bird.domain.config_path"}}
{{- printf "%s%s.conf" .top.Values.bird_config_path  (include "bird.domain.config_name" .) -}}
{{- end }}

{{- /*
All bird.instance.* expect a instance-context that should be consisted of
:<< domainCtx
instance_number: 1
instance: instance_1
instance_config: everything nested under .Values.service_1.domain_1.instance_1
*/}}

{{- define "bird.instance.deployment_name" }}
{{- printf "%s-pxrs-%d-s%d-%d" .top.Values.global.region .domain_number .service_number .instance_number}}
{{- end }}
