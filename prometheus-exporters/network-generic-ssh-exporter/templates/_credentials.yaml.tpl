credentials:
  default:
    username: {{ .Values.network_generic_ssh_exporter.user }}
    password: {{ .Values.network_generic_ssh_exporter.password }}
  apic:
    username: {{ .Values.network_generic_ssh_exporter.apic_user }}
    password: {{ .Values.network_generic_ssh_exporter.apic_password }}
