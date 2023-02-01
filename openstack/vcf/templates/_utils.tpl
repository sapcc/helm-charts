{{- define "vcf_image" -}}
  {{- if contains "DEFINED" $.Values.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registryAlternateRegion }}/vcf-automation:{{$.Values.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "vcf_environment" }}
- name: PULUMI_BACKEND_URL
  value: file:///pulumi/etc
- name: PULUMI_CONFIG_PASSPHRASE
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: pulumi_config_passphrase
- name: VCF_OS_USERNAME
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: os_username
- name: VCF_OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: os_password
- name: VCF_OS_REGION
  value: "{{ .Values.global.region }}"
- name: VCF_CONFIG_DIR
  value: /pulumi/etc
- name: VCF_WORK_DIR
  value: /pulumi/vcf
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
{{- if hasKey .Values "esxi_password" }}
      key: esxi_password
{{- else }}
      key: vmware_password
{{- end }}
- name: VCF_VMWARE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: vcf-secret
      key: vmware_password
{{- end -}}
