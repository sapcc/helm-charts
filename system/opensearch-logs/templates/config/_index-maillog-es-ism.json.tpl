{
    "policy": {
        "policy_id": "index-mailloges-ism",
        "description": "Index ism policy for maillog kr",
        "default_state": "initial",
        "states": [
            {
                "name": "initial",
                "actions": [],
{{- if and .Values.s3.enabled .Values.global.index.mailloges.snapshots.enabled  }}
                "transitions": [
                    {
                        "state_name": "snapshot",
                        "conditions": {
                            "min_index_age": "{{ .Values.global.index.mailloges.min_index_age }}"
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
                        "repository": "{{ .Values.global.index.mailloges.snapshots.repository }}",
                        "snapshot": "{_SNAPSHOT_NAME_}"
                    }
                }
            ],
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_index_age": "{{ .Values.global.index.mailloges.min_index_age }}"
                        }
                    }
                ]
            },
{{- else }}
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_index_age": "{{ .Values.global.index.mailloges.min_index_age }}"
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
        "ism_template":
            {
                "index_patterns": [
                    "{{ .Values.global.index.mailloges.index_pattern }}"
                ],
                "priority": 2
            }
    }
}
