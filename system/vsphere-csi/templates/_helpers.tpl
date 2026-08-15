{{- define "csi.secret" -}}
[Global]
cluster-id = "{{ .Values.vcenter.cluster }}"
cluster-distribution = "{{ .Values.distribution }}"

[VirtualCenter {{ .Values.vcenter.url | quote }}]
insecure-flag = "true"
user = "{{ .Values.vcenter.username }}"
password = "{{ .Values.vcenter.password }}"
port = "443"
datacenters = "{{ .Values.vcenter.datacenter }}"
{{- end -}}
