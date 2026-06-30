{
    "policy": {
        "policy_id": "ds-audit-ism",
        "description": "Datastream (ds) ism policy for audit-ds",
        "schema_version": "{{ .Values.global.data_stream.schema_version }}",
        "default_state": "initial",
        "states": [
            {
                "name": "initial",
                "actions": [],
                "transitions": [
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_index_age": "{{ .Values.global.data_stream.audit.min_index_age }}"
                        }
                    },
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_size": "{{ .Values.global.data_stream.audit.min_size }}"
                        }
                    },
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_doc_count": "{{ .Values.global.data_stream.audit.min_doc_count }}"
                        }
                    }
                ]
            },
            {
                "name": "rollover",
                "actions": [
                    {
                        "retry": {
                            "count": 5,
                            "backoff": "exponential",
                            "delay": "1m"
                        },
                        "rollover": {
                            "min_doc_count": 5,
                            "min_index_age": "1d",
                            "copy_alias": false
                        }
                    }
                ],
{{- if and .Values.s3.enabled .Values.global.data_stream.audit.snapshots.enabled }}
                "transitions": [
                    {
                        "state_name": "snapshot",
                        "conditions": {
                            "min_index_age": "{{ .Values.global.data_stream.audit.min_index_age }}"
                        }
                    }
                ]
            },
            {
                "name": "snapshot",
                "actions": [
                    {
                        "retry": {
                            "count": 3,
                            "backoff": "exponential",
                            "delay": "1m"
                        },
                        "snapshot": {
                            "repository": "{{ .Values.global.data_stream.audit.snapshots.repository }}",
                            "snapshot": "{_SNAPSHOT_NAME_}"
                        }
                    }
                ],
                "transitions": [
                    {
{{- if .Values.global.data_stream.audit.searchable_snapshots.enabled }}
                        "state_name": "link_snapshot",
{{- else }}
                        "state_name": "delete",
{{- end }}
                        "conditions": {
                            "min_doc_count": 5
                        }
                    }
                ]
            },
{{- if .Values.global.data_stream.audit.searchable_snapshots.enabled }}
            {
                "name": "link_snapshot",
                "actions": [
                    {
                      "retry": {
                          "count": 3,
                          "backoff": "exponential",
                          "delay": "1m"
                      },
                      "convert_index_to_remote": {
                          "repository": "{{ .Values.global.data_stream.audit.snapshots.repository }}",
                          "snapshot": "{_SNAPSHOT_NAME_}",
                          "rename_pattern": "remote_$1"
                      }
                    }
                ],
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_doc_count": 5
                        }
                    }
                ]
            },
{{- end }}
{{- else }}
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_index_age": "{{ .Values.retention.ds }}"
                        }
                    }
                ]
            },
{{- end }}
            {
                "name": "delete",
                "actions": [
                    {
                        "retry": {
                            "count": 3,
                            "backoff": "exponential",
                            "delay": "1m"
                        },
                        "delete": {}
                    }
                ],
                "transitions": []
            }
        ],
        "ism_template": [
            {
                "index_patterns": [
                    "audit-datastream"
                ],
                "priority": 2
            }
        ]
    }
}
