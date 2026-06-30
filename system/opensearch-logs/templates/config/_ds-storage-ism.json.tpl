{
    "policy": {
        "policy_id": "ds-storage-ism",
        "description": "Datastream (ds) ism policy for storage-ds",
        "schema_version": "{{ .Values.global.data_stream.schema_version }}",
        "default_state": "initial",
        "states": [
            {
                "name": "initial",
                "actions": [
                    {
                        "retry": {
                            "count": 5,
                            "backoff": "exponential",
                            "delay": "1m"
                        },
                        "rollover": {
                            "min_primary_shard_size": "25gb",
                            "min_index_age": "7d"
                        }
                    }
                ],
{{- if and .Values.s3.enabled .Values.global.data_stream.storage.snapshots.enabled }}
                "transitions": [
                    {
                        "state_name": "snapshot",
                        "conditions": {
                            "min_index_age": "{{ .Values.global.data_stream.storage.min_index_age }}"
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
                            "repository": "{{ .Values.global.data_stream.storage.snapshots.repository }}",
                            "snapshot": "{_SNAPSHOT_NAME_}"
                        }
                    }
                ],
                "transitions": [
                    {
{{- if .Values.global.data_stream.storage.searchable_snapshots.enabled }}
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
{{- if .Values.global.data_stream.storage.searchable_snapshots.enabled }}
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
                          "repository": "{{ .Values.global.data_stream.storage.snapshots.repository }}",
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
                            "min_index_age": "{{ .Values.global.data_stream.storage.max_index_age }}"
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
                    "storage-datastream"
                ],
                "priority": 2
            }
        ]
    }
}
