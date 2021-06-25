{{- define "baremetal_temper_image" -}}
  {{- if contains "DEFINED" $.Values.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registryAlternateRegion }}/baremetal-temper:{{$.Values.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "baremetal_temper_environment" }}
- name:  debug
  value: 'false'
- name:  config-path
  value: '/etc/config/temper.yaml'
- name:  number-workers
  value: '20'

- name: redfish_password
  valueFrom:
    secretKeyRef:
      name: baremetal-temper-secret
      key: redfish_password
- name: netbox_token
  valueFrom:
    secretKeyRef:
      name: baremetal-temper-secret
      key: netbox_token
- name: openstack_password
  valueFrom:
    secretKeyRef:
      name: baremetal-temper-secret
      key: openstack_password
- name: arista_password
  valueFrom:
    secretKeyRef:
      name: baremetal-temper-secret
      key: arista_password
- name: aci_password
  valueFrom:
    secretKeyRef:
      name: baremetal-temper-secret
      key: aci_password
- name: deployment_openstack_password
  valueFrom:
    secretKeyRef:
      name: baremetal-temper-secret
      key: deployment_openstack_password
{{- end -}}
