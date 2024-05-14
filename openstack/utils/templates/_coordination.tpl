{{- define "utils.coordination.volume_name" -}}
"{{ .Chart.Name }}-coordination"
{{- end }}

{{- define "utils.coordination.volume_mount" }}
{{- if eq .Values.coordinationBackend "file" }}
- name: coordination
  # The parent dir of mountPath only matches by convention to $state_path in config and Dockerfile
  mountPath: /var/lib/{{ .Values.coordinationBackendMountPath | default .Chart.Name }}/coordination
{{- end }}
{{- end }}

{{- define "utils.coordination.volumes" }}
{{- if eq .Values.coordinationBackend "file" }}
- name: coordination
  persistentVolumeClaim:
    claimName: {{ include "utils.coordination.volume_name" . }}
{{- end }}
{{- end }}


{{- define "utils.coordination.persistent_volume_claim" }}
{{- if eq .Values.coordinationBackend "file" }}
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: {{ include "utils.coordination.volume_name" . }}
  annotations:
  {{- if .Values.coordinationBackendStorageClass }}
    volume.beta.kubernetes.io/storage-class: {{ .Values.coordinationBackendStorageClass | quote }}
  {{- end }}
  {{- if  index .Values "owner-info" }}
    ccloud/support-group: {{  index .Values "owner-info" "support-group" | quote }}
    ccloud/service: {{  index .Values "owner-info" "service" | quote }}
  {{- end }}
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: {{ .Values.coordinationBackendStorageSize | default "1G" | quote }}
{{- end }}
{{- end }}
