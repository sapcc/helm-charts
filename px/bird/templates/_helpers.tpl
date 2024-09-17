
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

{{- define "bird.domain.labels" }}
app: {{ include "bird.instance.deployment_name" . | quote }}
pxservice: '{{ .service_number }}'
pxdomain: '{{ .domain_number }}'
{{- end }}

{{- define "bird.instance.labels" }}
app: {{ include "bird.instance.deployment_name" . | quote }}
pxservice: '{{ .service_number }}'
pxdomain: '{{ .domain_number }}'
pxinstance: '{{ .instance_number }}'
{{- end }}

{{- define "bird.alert.labels" }}
alert-tier: px
alert-service: px
{{- end }}

{{- define "bird.domain.affinity" }}
{{- if len .top.Values.apods  | eq 0 }}
{{- fail "You must supply at least one apod for scheduling" -}}
{{ end }}
nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.cloud.sap/apod
          operator: In
          values: 
          {{- range $site := keys .top.Values.apods | sortAlpha }}
          {{- range get $.top.Values.apods  $site | sortAlpha }}
          - {{ . }}
          {{- end }}
          {{- end }}
          {{- if .top.Values.prevent_hosts }}
        - key: kubernetes.cloud.sap/host
          operator: NotIn
          values:
          {{ .top.Values.prevent_hosts | toYaml | indent  16 }}
          {{- end }}
podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - topologyKey: "kubernetes.cloud.sap/host"
      labelSelector:
        matchExpressions:
        - key: pxservice
          operator: In
          values:
          - {{ .service_number | quote }}
          {{- if and (ge (len .top.Values.global.availability_zones ) 2) $.top.Values.az_redundancy }}
          {{- if lt (len (keys .top.Values.apods))  2 }}
          {{- fail "If the region consists of multiple AZs, PX must be scheduled in at least 2" -}}
          {{- end }}
    - topologyKey: topology.kubernetes.io/zone
      labelSelector:
        matchExpressions:
        - key: pxservice
          operator: In
          values:
          - {{ .service_number | quote }}
        - key: pxdomain
          operator: In
          values:
          - {{ .domain_number | quote }}
{{- end }}
{{- end }}

{{ define "bird.domain.tolerations"}}
{{- if .top.Values.tolerate_arista_fabric }}
- key: "fabric"
  operator: "Equal"
  value: "arista"
  effect: "NoSchedule"
{{- end }}
{{- end }}
