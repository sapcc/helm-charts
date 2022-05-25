{{- define "vcf_image" -}}
  {{- if contains "DEFINED" $.Values.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registryAlternateRegion }}/vcf-automation:{{$.Values.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "vcf_environment" }}
- name: AUTOMATION_WORK_DIR
  value: /pulumi/vcf
- name: AUTOMATION_CONFIG_DIR
  value: /pulumi/etc
- name: AUTOMATION_OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: os_password
- name: AUTOMATION_OS_USERNAME
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: os_username
- name: AUTOMATION_OS_REGION
  value: "{{ .Values.global.region }}"
- name: PULUMI_BACKEND_URL
  value: file:///pulumi/automation/etc
- name: PULUMI_CONFIG_PASSPHRASE
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: pulumi_config_passphrase
- name: VCF_ESXI_LICENSE
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: esxi_license
- name: VCF_ESXI_LICENSE_MANAGEMENT
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: esxi_license_management
- name: VCF_ESXI_PASSWORD
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: esxi_password
- name: VCF_VMWARE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: vmware_password
{{- end -}}
