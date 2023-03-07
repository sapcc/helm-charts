Defaults:
  auth_style: basic_auth
  username: {{ .Values.global.netapp_exporter_user }}
  password: {{ .Values.global.netapp_exporter_password }}
  use_insecure_tls: true
  exporters:
    - prom1
Exporters:
  prom1:
    exporter: Prometheus
    global_prefix: netapp_
Pollers:{{`
  {{ .Name }}:
    addr: {{ .Host }}
    datacenter: {{ .AvailabilityZone }}
    labels:
      - availability_zone: {{ .AvailabilityZone }}
      - cluster: {{ .Name }} 
    collectors:
      - Zapi:
        - limited.yaml
      - ZapiPerf:
        - limited.yaml`}}
      {{- if eq .Values.global.region "qa-de-1" }}
      - ems
      {{- end }}
