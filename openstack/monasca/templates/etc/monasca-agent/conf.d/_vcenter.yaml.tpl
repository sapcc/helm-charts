init_config:
  check_frequency: 60
  collect_period: 300

instances:
{{ toYaml .Values.monasca_vcenter_config | indent 2 }}
