[ml2_cc_fabric]
driver_config_path = /etc/neutron/plugins/ml2/cc-fabric-driver-config.yaml
{{- if .Values.cc_fabric.handle_all_l3_gateways }}
handle_all_l3_gateways = {{ .Values.cc_fabric.handle_all_l3_gateways }}
{{- end }}
