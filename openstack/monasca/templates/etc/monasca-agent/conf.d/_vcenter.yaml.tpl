init_config:
  check_frequency: 300
  collect_period: 300

instances:
{{ toYaml .Values.monasca_vcenter_config | indent 2 }}
