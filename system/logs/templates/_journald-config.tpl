{{- define "journald.receiver" }}
journald:
  directory: /var/log/journal
  storage: file_storage/journald
  start_at: beginning
  operators:
    - id: journal-label
      type: add
      field: attributes["log.type"]
      value: "journald"
{{ end }}

{{- define "journald.transform" }}
transform/journal:
  error_mode: ignore
  log_statements:
    - context: log
      statements:
        - merge_maps(log.cache, log.body, "upsert") where IsMatch(log.body, "^\\{")
        - set(log.attributes["message"], log.cache["MESSAGE"])
        - set(log.attributes["code_file"], log.cache["CODE_FILE"])
        - set(log.attributes["code_func"], log.cache["CODE_FUNC"])
        - set(log.attributes["code_line"], log.cache["CODE_LINE"])
        - set(log.attributes["incovation_id"], log.cache["INVOCATION_ID"])
        - set(log.attributes["message_id"], log.cache["MESSAGE_ID"])
        - set(log.attributes["priority"], log.cache["PRIORITY"])
        - set(log.attributes["syslog_facility"], log.cache["SYSLOG_FACILITY"])
        - set(log.attributes["syslog_identifier"], log.cache["SYSLOG_IDENTIFIER"])
        - set(log.attributes["tid"], log.cache["TID"])
        - set(log.attributes["unit"], log.cache["UNIT"])
        - set(log.attributes["boot_id"], log.cache["_BOOT_ID"])
        - set(log.attributes["cao_effective"], log.cache["_CAP_EFFECTIVE"])
        - set(log.attributes["cmdline"], log.cache["_CMDLINE"])
        - set(log.attributes["exe"], log.cache["_EXE"])
        - set(log.attributes["gid"], log.cache["_GID"])
        - set(log.attributes["hostname"], log.cache["_HOSTNAME"])
        - set(log.attributes["machine_id"], log.cache["_MACHINE_ID"])
        - set(log.attributes["pid"], log.cache["_PID"])
        - set(log.attributes["runtime_scope"], log.cache["_RUNTIME_SCOPE"])
        - set(log.attributes["selinux_context"], log.cache["_SELINUX_CONTEXT"])
        - set(log.attributes["source_realtime_timestamp"], log.cache["_SOURCE_REALTIME_TIMESTAMP"])
        - set(log.attributes["systemd_cgroup"], log.cache["_SYSTEMD_CGROUP"])
        - set(log.attributes["systemd_slice"], log.cache["_SYSTEMD_SLICE"])
        - set(log.attributes["systemd_unit"], log.cache["_SYSTEMD_UNIT"])
        - set(log.attributes["transport"], log.cache["_TRANSPORT"])
        - set(log.attributes["uid"], log.cache["_UID"])
        - set(log.attributes["cursor"], log.cache["__CURSOR"])
        - set(log.attributes["monotonic_timestamp"], log.cache["__MONOTONIC_TIMESTAMP"])
        - delete_key(log.attributes, "log.cache")
{{- end }}

{{- define "journald.pipeline" }}
logs/journald:
  receivers: [journald]
  processors: [attributes/cluster,transform/journal]
  exporters: [forward]
{{- end }}
