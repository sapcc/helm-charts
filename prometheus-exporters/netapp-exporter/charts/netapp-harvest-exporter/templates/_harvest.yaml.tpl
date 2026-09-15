Defaults:
  auth_style: basic_auth
  credentials_file: /opt/harvest/credentials.yaml
  use_insecure_tls: true
  exporters:
    - prom1
Exporters:
  prom1:
    exporter: Prometheus
    global_prefix: netapp_
    port: 13000
Pollers:{{`
  {{ .Name }}:
    {{- if .Ip }}
    addr: {{ .Ip }}
    {{- else }}
    addr: {{ .Host }}
    {{- end }}
    datacenter: {{ .AvailabilityZone }}
    labels:
      - availability_zone: {{ .AvailabilityZone }}
      - filer: {{ .Name }}
      - host: {{ .Host }}`}}
    collectors:
      - Rest:
        - limited.yaml
      - RestPerf:
        - limited.yaml
      {{- if eq .Values.global.region "qa-de-1" }}
      - Ems
      {{- end }}
