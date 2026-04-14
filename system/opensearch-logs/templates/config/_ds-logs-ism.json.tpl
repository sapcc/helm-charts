{
    "policy": {
        "policy_id": "ds-logs-ism",
        "description": "Datastream (ds) ism policy for logs-ds",
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
{{- if and .Values.s3.enabled .Values.global.data_stream.logs.snapshots.enabled }}
                "transitions": [
                    {
                        "state_name": "snapshot",
                        "conditions": {
                            "min_index_age": "7d"
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
                            "repository": "{{ .Values.global.data_stream.logs.snapshots.repository }}",
                            "snapshot": "{_SNAPSHOT_NAME_}"
                        }
                    } 
                ],
                "transitions": [
                    {
                        "state_name": "link_snapshot",
                        "conditions": {
                            "min_doc_count": 5
                        }
                    }
                ]
            },
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
                          "repository": "{{ .Values.global.data_stream.logs.snapshots.repository }}",
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
                    "logs-datastream"
                ],
                "priority": 2
            }
        ]
    }
}
