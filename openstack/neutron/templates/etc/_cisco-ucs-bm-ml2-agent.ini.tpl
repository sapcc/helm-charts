[securitygroup]
# No security groups on bare metal
firewall_driver = neutron.agent.firewall.NoopFirewallDriver
enable_security_group = False

{{- range $host, $ucs := .Values.cisco_ucsm_bm }}
{{- if ne $host "example.com"}}
[ml2_cisco_ucsm_bm_ip:{{$host}}]
ucsm_username = {{required "A valid ucs-config required!" $ucs.user}}
ucsm_password = {{required "A valid ucs-config required!" $ucs.password}}
physical_network = {{required "A valid ucs-config required!" $ucs.physical_network}}
vnic_paths = {{required "A valid ucs-config required!" $ucs.vnic_paths}}
{{- end }}
{{- end }}
