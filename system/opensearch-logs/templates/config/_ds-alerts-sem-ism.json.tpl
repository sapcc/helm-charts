{
    "policy": {
        "policy_id": "ds-alerts-sem-ism",
        "description": "Datastream (ds) ism policy for alerts-sem-ds",
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
                            "min_index_age": "{{ .Values.global.data_stream.alerts_sem.min_index_age }}"
                        }
                    },
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_size": "{{ .Values.global.data_stream.alerts_sem.min_size }}"
                        }
                    },
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_doc_count": "{{ .Values.global.data_stream.alerts_sem.min_doc_count }}"
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
                "transitions": []
            }
        ],
        "ism_template": [
            {
                "index_patterns": [
                    "alerts-sem-datastream"
                ],
                "priority": 2
            }
        ]
    }
}
