{{- define "journald.receiver" }}
journald:
  directory: /var/log/journal
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
        - merge_maps(cache, body, "upsert") where IsMatch(body, "^\\{")
        - set(attributes["message"], cache["MESSAGE"])
        - set(attributes["code_file"], cache["CODE_FILE"])
        - set(attributes["code_func"], cache["CODE_FUNC"])
        - set(attributes["code_line"], cache["CODE_LINE"])
        - set(attributes["incovation_id"], cache["INVOCATION_ID"])
        - set(attributes["message_id"], cache["MESSAGE_ID"])
        - set(attributes["priority"], cache["PRIORITY"])
        - set(attributes["syslog_facility"], cache["SYSLOG_FACILITY"])
        - set(attributes["syslog_identifier"], cache["SYSLOG_IDENTIFIER"])
        - set(attributes["tid"], cache["TID"])
        - set(attributes["unit"], cache["UNIT"])
        - set(attributes["boot_id"], cache["_BOOT_ID"])
        - set(attributes["cao_effective"], cache["_CAP_EFFECTIVE"])
        - set(attributes["cmdline"], cache["_CMDLINE"])
        - set(attributes["exe"], cache["_EXE"])
        - set(attributes["gid"], cache["_GID"])
        - set(attributes["hostname"], cache["_HOSTNAME"])
        - set(attributes["machine_id"], cache["_MACHINE_ID"])
        - set(attributes["pid"], cache["_PID"])
        - set(attributes["runtime_scope"], cache["_RUNTIME_SCOPE"])
        - set(attributes["selinux_context"], cache["_SELINUX_CONTEXT"])
        - set(attributes["source_realtime_timestamp"], cache["_SOURCE_REALTIME_TIMESTAMP"])
        - set(attributes["systemd_cgroup"], cache["_SYSTEMD_CGROUP"])
        - set(attributes["systemd_slice"], cache["_SYSTEMD_SLICE"])
        - set(attributes["systemd_unit"], cache["_SYSTEMD_UNIT"])
        - set(attributes["transport"], cache["_TRANSPORT"])
        - set(attributes["uid"], cache["_UID"])
        - set(attributes["cursor"], cache["__CURSOR"])
        - set(attributes["monotonic_timestamp"], cache["__MONOTONIC_TIMESTAMP"])
        - delete_key(attributes, "cache")
{{- end }}

{{- define "journald.pipeline" }}
logs/journald:
  receivers: [journald]
  processors: [attributes/cluster,transform/journal]
  exporters: [forward]
{{- end }}