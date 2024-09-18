{{- define "bird.domain.configMapName" -}}
{{-  printf "v4-service-%d-domain-%d" .service_number .domain_number }}
{{- end }}

{{- define "bird.domain.config_path"}}
{{- /* Try new path first, if we fail fall back to old path */ -}}
{{- $confFile := printf "%s.conf" (include "bird.domain.configMapName" .) -}}
{{- $filePath := printf "%s%s/%s" .top.Values.bird_config_path .top.Values.global.region $confFile -}}
{{- $newPath := $filePath -}}
{{- if not (.top.Files.Glob $filePath) -}}
  {{- /* fall back to legacy path */ -}}
  {{- $confFile = printf "%s-pxrs-%d-s%d.conf" .top.Values.global.region .domain_number .service_number -}}
  {{- $filePath = printf "%s%s" .top.Values.bird_config_path $confFile -}}
  {{- if not (.top.Files.Glob $filePath) -}}
    {{- fail (printf "cannot find bird config file, tried %s and legacy path %s" $newPath $filePath ) -}}
  {{- end }}
{{- end }}
{{- $filePath }}
{{- end }}

{{- define "bird.statefulset.deployment_name" }}
{{- printf "routeserver-v4-service-%d-domain-%d-%d" .service_number .domain_number .instance_number }}
{{- end }}

{{- define "bird.domain.labels" }}
app: {{ include "bird.domain.deployment_name" . | quote }}
pxservice: '{{ .service_number }}'
pxdomain: '{{ .domain_number }}'
service: {{ .top.Release.Name | quote }}
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
          values: {{ .top.Values.prevent_hosts | toYaml | nindent  10 }}
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
