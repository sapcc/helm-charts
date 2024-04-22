credentials:
  default:
    username: {{ .Values.network_generic_ssh_exporter.user }}
    password: {{ .Values.network_generic_ssh_exporter.password }}
  apic:
    username: {{ .Values.network_generic_ssh_exporter.apic_user }}
    password: {{ .Values.network_generic_ssh_exporter.apic_password }}
lookup_sources:
  metis:
    host: {{ .Values.network_generic_ssh_exporter.metis.host }}
    port: 3306
    username: {{ .Values.network_generic_ssh_exporter.metis.user }}
    password: {{ .Values.network_generic_ssh_exporter.metis.password }}
    driver: mysql
    mappings:
      router_project: SELECT DISTINCT id, project_id FROM neutron.routers
