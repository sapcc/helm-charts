{{- define "bird.afis" -}}
{{ $afis := list }}
{{- range $k, $v := .domain_config }}
  {{ if and (hasPrefix "network_v" $k) $v }}
    {{- $afis = append $afis (trimPrefix "network_" $k) }}
  {{- end }}
{{- end }}
{{ $afis | toJson }}
{{- end }}

{{- define "bird.statefulset.configMapName" -}}
{{- printf "%s-service-%d-domain-%d" .afi .service_number .domain_number }}
{{- end }}

{{- define "bird.domain.config_path"}}
{{- /* Try new path first, if we fail fall back to old path */ -}}
{{- $confFile := printf "%s.conf" (include "bird.statefulset.configMapName" .) -}}
{{- $filePath := printf "%s%s/%s" .top.Values.bird_config_path .top.Values.global.region $confFile -}}
{{- $newPath := $filePath -}}
{{- if not (.top.Files.Glob $filePath) -}}
  {{- if eq .afi "v6" -}}
    {{- fail "v6 address family not supported with legacy file path" -}}
  {{- end }}
  {{- /* fall back to legacy path */ -}}
  {{- $confFile = printf "%s-pxrs-%d-s%d.conf" .top.Values.global.region .domain_number .service_number -}}
  {{- $filePath = printf "%s%s" .top.Values.bird_config_path $confFile -}}
  {{- if not (.top.Files.Glob $filePath) -}}
    {{- fail (printf "cannot find bird config file, tried %s and legacy path %s" $newPath $filePath ) -}}
  {{- end }}
{{- end }}
{{- $filePath }}
{{- end }}

{{- define "bird.statefulset.name" }}
{{- printf "routeserver-%s-service-%d-domain-%d" .afi .service_number .domain_number }}
{{- end }}

{{- define "bird.domain.labels" }}
pxservice: '{{ .service_number }}'
px.cloud.sap/service: {{ .service_number | quote }}
pxdomain: '{{ .domain_number }}'
px.cloud.sap/domain: {{ .domain_number | quote }}
service: {{ .top.Release.Name | quote }}
{{- end }}

{{- define "bird.afi.labels" }}
px.cloud.sap/afi: {{ .afi | quote }}
{{- end }}

{{- define "bird.statefulset.labels" }}
app: {{ include "bird.statefulset.name" . | quote }}
px.cloud.sap/component: "routeserver"
{{- include "bird.domain.labels" . }}
{{- include "bird.afi.labels" . }}
{{- end }}


{{- define "bird.afi.network "}}

{{- end }}


{{- define "bird.alert.labels" }}
alert-tier: px
alert-service: px
{{- end }}


{{- define "bird.topology_spread" }}
- maxSkew: 1
  # minDomains: {{ len .top.Values.global.availability_zones }} 
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: ScheduleAnyway
  labelSelector: 
    matchExpressions:
      - key: px.cloud.sap/component
        operator: In
        values:
        - routeserver
      - key: px.cloud.sap/afi
        operator: In
        values:
        - {{ .afi | quote }}
      - key: px.cloud.sap/service
        operator: In
        values:
        - {{ .service_number | quote }}
  # matchLabelKeys: <list> # optional; beta since v1.27
  nodeAffinityPolicy: Honor # respect affinities below
  nodeTaintsPolicy: Ignore # default value 
{{- end }}

{{- define "bird.domain.affinity" }}
{{- if len .top.Values.apods  | eq 0 }}
{{- fail "You must supply at least one apod for scheduling" -}}
{{ end }}
nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: {{ .top.Values.rackKey | quote }}
          operator: In
          values: 
          {{- range $site := keys .top.Values.apods | sortAlpha }}
          {{- range get $.top.Values.apods  $site | sortAlpha }}
          - {{ . }}
          {{- end }}
          {{- end }}
          {{- if .top.Values.prevent_hosts }}
        - key: {{ .top.Values.nodeKey | quote}}
          operator: NotIn
          values: {{ .top.Values.prevent_hosts | toYaml | nindent  10 }}
          {{- end }}
podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - topologyKey: {{ .top.Values.nodeKey | quote}}
      labelSelector:
        matchExpressions:
        - key: px.cloud.sap/afi
          operator: In
          values:
          - {{ .afi | quote }}
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
        - key: px.cloud.sap/afi
          operator: In
          values:
          - {{ .afi | quote }}
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
