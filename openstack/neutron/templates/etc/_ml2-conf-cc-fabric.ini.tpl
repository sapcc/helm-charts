[ml2_cc_fabric]
driver_config_path = /etc/neutron/plugins/ml2/cc-fabric-driver-config.yaml
driver_config_credentials_path = /etc/neutron/cc-fabric-secrets/cc-fabric-driver-credentials.yaml
{{- if .Values.cc_fabric.handle_all_l3_gateways }}
handle_all_l3_gateways = {{ .Values.cc_fabric.handle_all_l3_gateways }}
{{- end }}
