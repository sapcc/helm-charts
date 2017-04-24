init_config:

instances:
- name: {{ .Values.monasca_agent_vcenter_cluster_a_cluster }}
  vcenter_ip: {{ .Values.monasca_agent_vcenter_cluster_a_host }}
  username: {{ .Values.monasca_agent_vcenter_cluster_a_username }}
  password: {{ .Values.monasca_agent_vcenter_cluster_a_password }}
  clusters: [{{ .Values.monasca_agent_vcenter_cluster_a_cluster }}]
  dimensions:
    service: monitoring
    component: {{ .Values.monasca_agent_vcenter_cluster_b_cluster }}
- name: {{ .Values.monasca_agent_vcenter_cluster_b_cluster }}
  vcenter_ip: {{ .Values.monasca_agent_vcenter_cluster_b_host }}
  username: {{ .Values.monasca_agent_vcenter_cluster_b_username }}
  password: {{ .Values.monasca_agent_vcenter_cluster_b_password }}
  clusters: [{{ .Values.monasca_agent_vcenter_cluster_b_cluster }}]
  dimensions:
    service: monitoring
    component: {{ .Values.monasca_agent_vcenter_cluster_b_cluster }}
