{{- define "utils.snippets.kubernetes_entrypoint_init_container" }}
  {{- $envAll := index . 0 }}
  {{- $params := index . 1 }}
- name: kubernetes-entrypoint
  {{- $version := $envAll.Values.utils.kubernetes_entrypoint_version }}
  {{- $build := default "latest" (get $envAll.Values.global.kubernetes_entrypoint_build_version $envAll.Values.utils.kubernetes_entrypoint_version) }}
  image: {{ $envAll.Values.global.registry }}/shared-app-images/kubernetes-entrypoint:{{ $version }}-{{ $build }}
  command:
  - /kubernetes-entrypoint
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
