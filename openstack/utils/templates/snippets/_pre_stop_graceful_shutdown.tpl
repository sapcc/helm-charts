{{- define "utils.snippets.pre_stop_graceful_shutdown" }}
exec:
  command: [
    # Introduce a delay to the shutdown sequence to wait for the
    # pod eviction event to propagate.
    "/bin/sleep",
    "{{ coalesce .Values.shutdownDelaySeconds .Values.global.shutdownDelaySeconds 10 }}"
  ]
{{- end }}
