{
    "policy": {
        "policy_id": "ds-logs-ism",
        "description": "Datastream (ds) ism policy for logs-ds",
        "schema_version": "{{ .Values.global.data_stream.schema_version }}",
        "default_state": "hot",
        "states": [
            {
                "name": "hot",
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
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_index_age": "{{ .Values.retention.ds }}"
                        }
                    }
                ]
            },
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
                    ".ds-logs-datastream*"
                ],
                "priority": 100
            }
        ]
    }
}
