{{- define "utils.snippets.kubernetes_entrypoint_init_container" }}
  {{- $envAll := index . 0 }}
  {{- $params := index . 1 }}
- name: kubernetes-entrypoint
  image: {{ $envAll.Values.global.ghcrIoMirror }}/sapcc/kubernetes-entrypoint:{{ $envAll.Values.utils.kubernetesEntrypoint.imageVersion }}
  command:
  - kubernetes-entrypoint
  env:
  - name: COMMAND
    value: "true"
  - name: POD_NAME
    valueFrom: {fieldRef: {fieldPath: metadata.name}}
  - name: NAMESPACE
    valueFrom: {fieldRef: {fieldPath: metadata.namespace}}
  {{- range $k, $v := $params }}
  - name: DEPENDENCY_{{ $k | upper }}
    value: {{ $v }}
  {{- end }}
{{- end }}
